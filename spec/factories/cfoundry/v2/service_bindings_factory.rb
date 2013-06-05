FactoryGirl.define do
  factory :service_binding, :class => CFoundry::V2::ServiceBinding do
    sequence(:guid) { |n| "service-binding-guid-#{n}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end