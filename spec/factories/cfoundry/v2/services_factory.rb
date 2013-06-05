FactoryGirl.define do
  factory :service, :class => CFoundry::V2::Service do
    sequence(:guid) { |n| "service-guid-#{n}" }
    sequence(:label) { |n| "service-label-#{n}" }
    service_plans { [build(:service_plan)] }
    extra { "{}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end