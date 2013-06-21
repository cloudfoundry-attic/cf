FactoryGirl.define do
  factory :space, :class => CFoundry::V2::Space do
    sequence(:guid) { |n| "space-guid-#{n}" }
    sequence(:name) { |n| "space-name-#{n}" }
    domains { [build(:domain)] }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end
