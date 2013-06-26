module CFoundry
  FactoryGirl.define do
    factory :quota_definition, class: CFoundry::V2::QuotaDefinition do
      sequence(:guid) { |n| "quota-definition-guid-#{n}" }

      ignore do
        client { FactoryGirl.build(:client) }
      end

      initialize_with { new(guid, client) }
    end
  end
end
