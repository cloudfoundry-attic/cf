FactoryGirl.define do
  factory :stack, :class => CFoundry::V2::Stack do
    sequence(:guid) { |n| "stack-guid-#{n}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end