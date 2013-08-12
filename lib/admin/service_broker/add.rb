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
    input :token,
      :desc => "Broker token"

    def add_service_broker
      broker = client.service_broker

      broker.name = input[:name]
      finalize
      broker.broker_url = input[:url]
      finalize
      broker.token = input[:token]
      finalize

      with_progress("Adding service broker #{broker.name}") do
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

    def ask_token
      ask("Token")
    end
  end
end
