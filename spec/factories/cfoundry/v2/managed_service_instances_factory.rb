FactoryGirl.define do
  factory :managed_service_instance, :class => CFoundry::V2::ManagedServiceInstance do
    sequence(:guid) { |n| "service-instance-guid-#{n}" }
    sequence(:name) { |n| "service-instance-name-#{n}" }
    service_plan { build(:service_plan) }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end
