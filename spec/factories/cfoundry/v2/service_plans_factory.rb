FactoryGirl.define do
  factory :service_plan, :class => CFoundry::V2::ServicePlan do
    sequence(:guid) { |n| "service-plan-guid-#{n}" }
    sequence(:name) { |n| "service-plan-name-#{n}" }
    extra { "{}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end