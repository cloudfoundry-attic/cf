require 'spec_helper'

describe CFAdmin::ServiceBroker::Remove do

  describe 'command metadata' do
    let(:command) { Mothership.commands[:remove_service_broker] }
    subject { command }
    its(:description) { should eq 'Remove a service broker' }
    it { expect(Mothership::Help.group(:admin)).to include(subject) }

    include_examples 'inputs must have descriptions'
  end

  describe 'running the command' do
    let(:client) { build(:client) }
    before do
      CFAdmin::ServiceBroker::Remove.client = client
    end

    describe 'successful behavior' do
      let(:service_broker) { build(:service_broker, :name => 'somebroker') }
      before do
        client.stub(:service_broker_by_name).with('somebroker').and_return(service_broker)
        service_broker.should_receive(:delete!)
      end

      it 'removes the service broker' do
        should_ask('Really remove somebroker?', {:default => false}) { true }

        capture_output { cf %W[remove-service-broker somebroker] }
        expect(output).to say("Removing service broker #{service_broker.name}... OK")
      end
    end

    describe 'error conditions' do
      context 'when the service broker does not exist' do
        it 'provides a helpful error message' do
          client.stub(:service_broker_by_name).with('doesnotexist').and_return(nil)

          capture_output { cf %W[remove-service-broker doesnotexist] }
          expect(error_output).to say("Unknown service_broker 'doesnotexist'.")
        end
      end
    end
  end
end
