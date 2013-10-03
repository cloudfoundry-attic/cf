require "cf/cli"

module CFAdmin::ServiceBroker
  class Update < CF::CLI
    def precondition
      check_target
    end

    desc "Update a service broker"
    group :admin
    input :broker, :argument => :required,
      :desc => "Service broker to update",
      :from_given => by_name(:service_broker, 'service broker')
    input :name, :argument => :optional,
      :desc => "New name"
    input :url,
      :desc => "New URL"
    input :username,
      :desc => "New basic authentication username"
    input :password,
      :desc => "New basic authentication password"

    def update_service_broker
      @broker = input[:broker]

      old_name = @broker.name

      @broker.name = input[:name]
      finalize
      @broker.broker_url = input[:url]
      finalize
      @broker.auth_username = input[:username]
      finalize
      @broker.auth_password = input[:password]
      finalize

      with_progress("Updating service broker #{old_name}") do
        @broker.update!
      end
    end

    private

    def ask_name
      ask("Name", :default => @broker.name)
    end

    def ask_url
      ask("URL", :default => @broker.broker_url)
    end

    def ask_username
      ask("Username", :default => @broker.auth_username)
    end

    def ask_password
      ask("Password", :default => @broker.auth_password)
    end
  end
end
