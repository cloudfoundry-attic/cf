FactoryGirl.define do
  factory :domain, :class => CFoundry::V2::Domain do
    guid { "domain-id-1" }
    name { "domain-name-1" }
    client nil
    initialize_with { new(guid, client) }
  end
end
