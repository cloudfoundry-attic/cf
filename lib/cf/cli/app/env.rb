require "cf/cli/app/base"

module CF::App
  class Env < Base
    VALID_ENV_VAR = /^[a-zA-Za-z_][[:alnum:]_]*$/

    desc "Show all environment variables set for an app"
    group :apps, :info
    input :app, :desc => "Application to inspect the environment of",
          :argument => true, :from_given => by_name(:app)
    def env
      app = input[:app]

      vars =
        with_progress("Getting env for #{c(app.name, :name)}") do |s|
          app.env
        end

      line unless quiet?

      vars.each do |name, val|
        line "#{c(name, :name)}: #{val}"
      end
    end

    desc "Set an environment variable"
    group :apps, :info
    input :app, :desc => "Application to set the variable for",
          :argument => true, :from_given => by_name(:app)
    input :name, :desc => "Variable name", :argument => true
    input :value, :desc => "Variable value", :argument => :optional
    input :restart, :desc => "Restart app after updating?", :default => false

    def set_env
      app = input[:app]
      name, value = parse_name_and_value!

      with_progress("Updating env variable #{c(name, :name)} for app #{c(app.name, :name)}") do
        app.env[name] = value
        app.update!
      end

      restart_if_necessary(app)
    end

    desc "Remove an environment variable"
    group :apps, :info
    input :app, :desc => "Application to set the variable for",
          :argument => true, :from_given => by_name(:app)
    input :name, :desc => "Variable name", :argument => true
    input :restart, :desc => "Restart app after updating?", :default => false
    def unset_env
      app = input[:app]
      name = input[:name]

      with_progress("Unsetting #{c(name, :name)} for app #{c(app.name, :name)}") do
        app.env.delete(name)
        app.update!
      end

      restart_if_necessary(app)
    end

    private

    def restart_if_necessary(app)
      unless input[:restart]
        line c("TIP: Use 'cf push' to ensure your env variable changes take effect.", :warning)
        return
      end

      if app.started?
        invoke :restart, :app => app
      else
        line "Your app was unstarted. Starting now."
        invoke :start, :app => app
      end
    end

    def parse_name_and_value!
      name = input[:name]
      value = input[:value]

      if name["="]
        name, new_value, extra_values = name.split("=")
        fail "You attempted to specify the value of #{name} twice." if value
        fail "Invalid format: environment variable definition contains too many occurences of '='" if extra_values
        value = new_value
      end

      unless name =~ VALID_ENV_VAR
        fail "Invalid format: environment variable names cannot start with a number" if name[0] =~ /\d/
        fail "Invalid format: environment variable names can only contain alphanumeric characters and underscores"
      end

      return name, value
    end
  end
end
