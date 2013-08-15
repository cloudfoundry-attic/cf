require "cf/cli"

module CFAdmin::ServiceBroker
  class ServiceBrokers < CF::CLI
    def precondition
      check_target
    end

    desc "List registered service brokers"
    group :admin

    def service_brokers
      brokers = nil
      with_progress('Getting service brokers') do
        brokers = client.service_brokers
      end

      line unless quiet?

      table(
        %w(Name URL),
        brokers.collect { |broker|
          [c(broker.name, :name), broker.broker_url]
        }
      )
    end

  end
end
