FactoryGirl.define do
  factory :app, :class => CFoundry::V2::App do
    sequence(:guid) { |n| "app-guid-#{n}" }
    sequence(:name) { |n| "app-name-#{n}" }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end