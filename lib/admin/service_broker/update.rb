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
    input :token,
      :desc => "New token"

    def update_service_broker
      @broker = input[:broker]

      old_name = @broker.name

      @broker.name = input[:name]
      finalize
      @broker.broker_url = input[:url]
      finalize
      @broker.token = input[:token]
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

    def ask_token
      ask("Token", :default => @broker.token)
    end
  end
end
