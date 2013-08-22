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
      :from_given => by_name(:service_broker)
    input :name, :argument => :optional,
      :desc => "New name"
    input :url,
      :desc => "New URL"
    input :token,
      :desc => "New token"

    def update_service_broker
      broker = input[:broker]

      old_name = broker.name

      broker.name = input[:name]
      finalize
      broker.broker_url = input[:url]
      finalize
      broker.token = input[:token]
      finalize

      with_progress("Updating service broker #{old_name}") do
        broker.update!
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
