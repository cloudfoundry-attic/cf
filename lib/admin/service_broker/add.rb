require "cf/cli"

module CFAdmin::ServiceBroker
  class Add < CF::CLI
    def precondition
      check_target
    end

    desc "Add a service broker"
    group :admin
    input :name, :argument => :optional,
      :desc => "Broker name"
    input :url,
      :desc => "Broker URL"
    input :username,
      :desc => "Broker basic authentication username"
    input :password,
      :desc => "Broker basic authentication password"

    def add_service_broker
      broker = client.service_broker

      broker.name = input[:name]
      finalize
      broker.broker_url = input[:url]
      finalize
      broker.auth_username = input[:username]
      finalize
      broker.auth_password = input[:password]
      finalize

      with_progress("Adding service broker #{c(broker.name, :name)}") do
        broker.create!
      end
    end

    private
    def ask_name
      ask("Name")
    end

    def ask_url
      ask("URL")
    end

    def ask_username
      ask("Username")
    end

    def ask_password
      ask("Password")
    end
  end
end
