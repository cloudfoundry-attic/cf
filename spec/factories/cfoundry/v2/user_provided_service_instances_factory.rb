FactoryGirl.define do
  factory :user_provided_service_instance, :class => CFoundry::V2::UserProvidedServiceInstance do
    sequence(:guid) { |n| "user-provided-service-instance-guid-#{n}" }
    sequence(:name) { |n| "user-provided-service-instance-name-#{n}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end
