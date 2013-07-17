FactoryGirl.define do
  factory :client, :class => CFoundry::V2::Client do
    initialize_with do
      new("http://api.example.com")
    end
  end
end
