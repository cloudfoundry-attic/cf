require "spec_helper"

describe CFAdmin::ServiceBroker::Add do
  let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_admin_dir" }

  stub_home_dir_with { fake_home_dir }

  let(:client) { build(:client) }

  let(:service_broker) { CFoundry::V2::ServiceBroker.new(nil, client) }

  before do
    CFAdmin::ServiceBroker::Add.client = client
    client.stub(:service_broker).and_return(service_broker)
  end

  it "creates a service broker when arguments are provided on the command line" do
    service_broker.stub(:create!)

    cf %W[add-service-broker --name cf-mysql --url http://cf-mysql.cfapp.io --username cfmysqlusername --password cfmysqlsecret]

    service_broker.name.should == 'cf-mysql'
    service_broker.broker_url.should == 'http://cf-mysql.cfapp.io'
    service_broker.auth_username.should == 'cfmysqlusername'
    service_broker.auth_password.should == 'cfmysqlsecret'

    service_broker.should have_received(:create!)
  end

  it "creates a service broker when only the name is provided" do
    service_broker.stub(:create!)

    stub_ask("URL").and_return("http://example.com")
    stub_ask("Username").and_return("username")
    stub_ask("Password").and_return("password")

    cf %W[add-service-broker cf-mysql]

    service_broker.name.should == 'cf-mysql'
    service_broker.broker_url.should == 'http://example.com'
    service_broker.auth_username.should == 'username'
    service_broker.auth_password.should == 'password'

    service_broker.should have_received(:create!)
  end

  it "creates a service broker when no arguments are provided" do
    service_broker.stub(:create!)

    stub_ask("Name").and_return("cf-mysql")
    stub_ask("URL").and_return("http://example.com")
    stub_ask("Username").and_return("username")
    stub_ask("Password").and_return("password")

    cf %W[add-service-broker]

    service_broker.name.should == 'cf-mysql'
    service_broker.broker_url.should == 'http://example.com'
    service_broker.auth_username.should == 'username'
    service_broker.auth_password.should == 'password'

    service_broker.should have_received(:create!)
  end
end
