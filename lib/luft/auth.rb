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
      return @client if @client
      @client = CFoundry::V2::Client.new("https://api.run.pivotal.io", false)
    end

    def login
      #delete_credentials
      get_credentials
    end

  #  def logout
  #    delete_credentials
  #  end
  #
  #  # just a stub; will raise if not authenticated
    def check(credentials)
      @auth_token = client.login(credentials)
      @authenticated = true
    end
  #
    def default_host
      "luft.com"
    end

    def host
      ENV['LUFT_HOST'] || default_host
    end

    def get_credentials # :nodoc:
      @credentials ||= ask_for_and_save_credentials
    end
  #
  #  def delete_credentials
  #    if netrc
  #      netrc.delete("api.#{host}")
  #      netrc.delete("code.#{host}")
  #      netrc.save
  #    end
  #    @api, @client, @credentials = nil, nil
  #  end
  #
  #  def netrc_path
  #    default = Netrc.default_path
  #    encrypted = default + ".gpg"
  #    if File.exists?(encrypted)
  #      encrypted
  #    else
  #      default
  #    end
  #  end
  #
  #  def netrc # :nodoc:
  #    @netrc ||= begin
  #      File.exists?(netrc_path) && Netrc.read(netrc_path)
  #    rescue => error
  #      if error.message =~ /^Permission bits for/
  #        perm = File.stat(netrc_path).mode & 0777
  #        abort("Permissions #{perm} for '#{netrc_path}' are too open. You should run `chmod 0600 #{netrc_path}` so that your credentials are NOT accessible by others.")
  #      else
  #        raise error
  #      end
  #    end
  #  end
  #
  #  def read_credentials
  #    if ENV['HEROKU_API_KEY']
  #      ['', ENV['HEROKU_API_KEY']]
  #    else
  #      # read netrc credentials if they exist
  #      if netrc
  #        # force migration of long api tokens (80 chars) to short ones (40)
  #        # #write_credentials rewrites both api.* and code.*
  #        credentials = netrc["api.#{host}"]
  #        if credentials && credentials[1].length > 40
  #          @credentials = [credentials[0], credentials[1][0, 40]]
  #          write_credentials
  #        end
  #
  #        netrc["api.#{host}"]
  #      end
  #    end
  #  end
  #
  #  def write_credentials
  #    FileUtils.mkdir_p(File.dirname(netrc_path))
  #    FileUtils.touch(netrc_path)
  #    unless running_on_windows?
  #      FileUtils.chmod(0600, netrc_path)
  #    end
  #    netrc["api.#{host}"] = self.credentials
  #    netrc["code.#{host}"] = self.credentials
  #    netrc.save
  #  end
  #
    def ask_for_credentials
      puts "Enter your Luft credentials."
      user = ask("Email: ")
      password = ask("Password: ") { |q| q.echo = "*" }
      {:username => user, :password => password}
    end

    def ask_for_and_save_credentials
      begin
        credentials = ask_for_credentials
        #write_credentials
        check(credentials)
      rescue CFoundry::Denied => e
        #delete_credentials
        display "Authentication failed."
        exit 1
      rescue Exception => e
        #delete_credentials
        raise e
      end
      credentials
    end
  end
end
