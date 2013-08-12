FactoryGirl.define do
  factory :service_broker, :class => CFoundry::V2::ServiceBroker do
    sequence(:guid) { |n| "service-broker-guid-#{n}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end
