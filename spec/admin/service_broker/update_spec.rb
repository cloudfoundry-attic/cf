require "spec_helper"

describe CFAdmin::ServiceBroker::Update do
  let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_admin_dir" }
  stub_home_dir_with { fake_home_dir }

  let(:client) { build(:client) }

  let(:service_broker) { CFoundry::V2::ServiceBroker.new(nil, client) }

  before do
    service_broker.name = 'formername'
    service_broker.broker_url = 'http://former.example.com'
    service_broker.auth_username = 'formerusername'
    service_broker.auth_password = 'formerpassword'

    CFAdmin::ServiceBroker::Update.client = client
    client.stub(:service_broker_by_name).with('formername').and_return(service_broker)
  end

  it "updates a service broker when arguments are provided on the command line" do
    service_broker.stub(:update!)

    cf %W[update-service-broker --broker formername --name cf-othersql --url http://other.cfapp.io --username username --password secret2]

    service_broker.name.should == 'cf-othersql'
    service_broker.broker_url.should == 'http://other.cfapp.io'
    service_broker.auth_username.should == 'username'
    service_broker.auth_password.should == 'secret2'

    service_broker.should have_received(:update!)
  end

  it "updates a service broker when no change arguments are provided" do
    service_broker.stub(:update!)

    stub_ask("Name", :default => 'formername').and_return("cf-othersql")
    stub_ask("URL", :default => 'http://former.example.com').and_return("http://other.example.com")
    stub_ask("Username", :default => 'formerusername').and_return("username2")
    stub_ask("Password", :default => 'formerpassword').and_return("password2")

    cf %W[update-service-broker formername]

    service_broker.name.should == 'cf-othersql'
    service_broker.broker_url.should == 'http://other.example.com'
    service_broker.auth_username.should == 'username2'
    service_broker.auth_password.should == 'password2'

    service_broker.should have_received(:update!)
  end
end
