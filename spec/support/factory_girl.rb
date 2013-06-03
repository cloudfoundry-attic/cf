require "factory_girl"

RSpec.configure do |config|
  FactoryGirl.factories.clear
  FactoryGirl.find_definitions
  config.include FactoryGirl::Syntax::Methods
end
