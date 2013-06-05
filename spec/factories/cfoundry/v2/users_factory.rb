FactoryGirl.define do
  factory :user, :class => CFoundry::V2::User do
    guid { "user-id-1" }
    client nil
    initialize_with { new(guid, client) }
  end
end
