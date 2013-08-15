require "spec_helper"

describe CFAdmin::ServiceBroker::ServiceBrokers do
  let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_admin_dir" }

  stub_home_dir_with { fake_home_dir }

  let(:client) { build(:client) }

  before do
    CFAdmin::ServiceBroker::ServiceBrokers.client = client
  end

  context "when there are no brokers registered" do
    let(:brokers_data) { [] }
    it "says there are no brokers" do
      client.should_receive(:service_brokers).and_return(brokers_data)
      mock_with_progress("Getting service brokers")
      cf %W[service-brokers]
      expect(stdout.string).to eq("\nName   URL\n")
    end
  end

  context "when there are brokers registered" do
    let(:brokers_data) { [ double(guid: 'guiddy', name: 'mysql', broker_url: 'http://mysql.example.com/') ] }

    it "lists the brokers" do
      client.should_receive(:service_brokers).and_return(brokers_data)
      mock_with_progress("Getting service brokers")
      cf %W[service-brokers]
      expect(stdout.string).to match(/\nName.*URL.*\nmysql.*mysql.example.com/)
    end
  end
end
