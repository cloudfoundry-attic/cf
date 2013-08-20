require "cf/cli"

module CFAdmin::ServiceBroker
  class Remove < CF::CLI
    def precondition
      check_target
    end

    desc "Remove a service broker"
    group :admin
    input :name, :argument => :required,
      :desc => "Service broker to remove",
      :from_given => by_name(:service_broker)
    input :really, :type => :boolean, :forget => true, :hidden => true,
      :default => proc { force? || interact }

    def remove_service_broker
      broker = input[:name]
      return unless input[:really, broker]

      with_progress("Removing service broker #{c(broker.name, :name)}") do
        broker.delete!
      end
    end

    private

    def ask_really(broker)
      ask("Really remove #{c(broker.name, :name)}?", :default => false)
    end

  end
end
