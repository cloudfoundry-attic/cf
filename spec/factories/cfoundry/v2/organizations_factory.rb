FactoryGirl.define do
  factory :organization, :class => CFoundry::V2::Organization do
    sequence(:guid) { |n| "organization-guid-#{n}" }
    sequence(:name) { |n| "organization-name-#{n}" }
    users { [build(:user)] }
    spaces { [build(:space)] }

    ignore do
      client { FactoryGirl.build(:client) }
    end

    initialize_with { new(guid, client) }
  end
end
