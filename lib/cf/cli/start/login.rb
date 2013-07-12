require "cf/cli/start/base"
require "cf/cli/populators/target"

module CF::Start
  class Login < Base
    def precondition
      check_target
    end

    desc "Authenticate with the target"
    group :start
    input :username, :value => :email, :desc => "Account email",
          :alias => "--email", :argument => :optional
    input :password, :desc => "Account password"
    input :organization, :desc => "Organization" , :aliases => %w{--org -o},
          :from_given => by_name(:organization)
    input :space, :desc => "Space", :alias => "-s",
          :from_given => by_name(:space)
    input :sso, :desc => "Log in via SSO",
          :alias => "--sso", :default => false
    def login
      show_context

      expected_prompts = if input[:sso]
        [:username, :passcode]
      else
        [:username, :password]
      end

      credentials = {
        :username => input[:username],
        :password => input[:password]
      }

      prompts = client.login_prompts

      # ask username first
      if prompts.key?(:username)
        type, label = prompts.delete(:username)
        credentials[:username] ||= ask_prompt(type, label)
      end

      info = target_info

      auth_token = nil
      authenticated = false
      failed = false
      remaining_attempts = 3

      until authenticated || remaining_attempts <= 0
        remaining_attempts -= 1
        failed = false

        unless force?
          ask_prompts(credentials, prompts.slice(*expected_prompts))
        end

        with_progress("Authenticating") do |s|
          begin
            auth_token = client.login(credentials.slice(*expected_prompts))
            authenticated = true
          rescue CFoundry::Denied
            return if force?
            s.fail do
              failed = true
              credentials = credentials.slice(:username)
            end
          end
        end
      end

      return if failed

      info.merge!(auth_token.to_hash)
      save_target_info(info)
      invalidate_client

      line if input.interactive?(:organization) || input.interactive?(:space)

      CF::Populators::Target.new(input).populate_and_save!
    ensure
      exit_status 1 if not authenticated
    end

    private

    def ask_prompts(credentials, prompts)
      prompts.each do |name, meta|
        type, label = meta
        credentials[name] ||= ask_prompt(type, label)
      end
    end

    def ask_prompt(type, label)
      if type == "password"
        options = { :echo => "*", :forget => true }
      else
        options = {}
      end

      ask(label, options)
    end
  end
end
