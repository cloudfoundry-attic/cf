require "cf/cli"

module CFAdmin::ServiceBroker
  class ServiceBrokers < CF::CLI
    def precondition
      check_target
    end

    desc "List registered service brokers"
    group :admin

    def service_brokers
      brokers = client.service_brokers
      table(
        %w(name url),
        brokers.collect { |broker|
          [c(broker.name, :name), broker.broker_url]
        }
      )
    end

  end
end
