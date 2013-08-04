require "cgi"
require "luft"
require "luft/client"
require "luft/helpers"
require "highline/import"
require "netrc"
require "cfoundry"

class Luft::Auth
  class << self
    include Luft::Helpers

    def client
      @client ||= CFoundry::V2::Client.new(target_uri.to_s, false)
    end

    def target_uri
      URI("https://api.run.pivotal.io")
    end

    def login
      delete_credentials
      get_credentials
    end

    def logout
      delete_credentials
    end

    # just a stub; will raise if not authenticated
    def check(credentials)
      @auth_token = client.login(credentials)
    end

    def get_credentials # :nodoc:
      @credentials ||= ask_for_and_save_credentials
    end

    def delete_credentials
      if netrc
        netrc.delete(target_uri.host)
        netrc.save
      end
      @client, @credentials = nil, nil
    end

    def netrc_path
      default = Netrc.default_path
      encrypted = default + ".gpg"
      if File.exists?(encrypted)
        encrypted
      else
        default
      end
    end

    def netrc # :nodoc:
      @netrc ||= begin
        File.exists?(netrc_path) && Netrc.read(netrc_path)
      rescue => error
        if error.message =~ /^Permission bits for/
          perm = File.stat(netrc_path).mode & 0777
          abort("Permissions #{perm} for '#{netrc_path}' are too open. You should run `chmod 0600 #{netrc_path}` so that your credentials are NOT accessible by others.")
        else
          raise error
        end
      end
    end

    def read_credentials
      if netrc
        @auth_token = netrc[target_uri.host][1].sub(/^bearer-/, "bearer ")
      end
    end

    def write_credentials(credentials)
      FileUtils.mkdir_p(File.dirname(netrc_path))
      FileUtils.touch(netrc_path)
      unless running_on_windows?
        FileUtils.chmod(0600, netrc_path)
      end
      netrc[target_uri.host] = [credentials[:username], @auth_token.auth_header.sub(/^bearer /, "bearer-")]
      netrc.save
    end

    def ask_for_credentials
      puts "Enter your Luft credentials."
      user = ask("Email: ")
      password = ask("Password: ") { |q| q.echo = "*" }
      {:username => user, :password => password}
    end

    def ask_for_and_save_credentials
      begin
        credentials = ask_for_credentials
        check(credentials)
        write_credentials(credentials)
      rescue CFoundry::Denied
        delete_credentials
        display "Authentication failed."
        exit 1
      rescue StandardError => e
        delete_credentials
        raise e
      end
      credentials
    end
  end
end
