FactoryGirl.define do
  factory :route, :class => CFoundry::V2::Route do
    guid { "route-id-1" }
    host { "route-host-1" }
    client nil
    initialize_with { new(guid, client) }
  end
end
