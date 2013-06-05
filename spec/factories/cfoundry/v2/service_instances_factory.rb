FactoryGirl.define do
  factory :service_instance, :class => CFoundry::V2::ServiceInstance do
    sequence(:guid) { |n| "service-instance-guid-#{n}" }
    sequence(:name) { |n| "service-instance-name-#{n}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end