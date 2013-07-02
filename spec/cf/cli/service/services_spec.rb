require "spec_helper"

module CF
  module Service
    describe Services do
      let(:command) { Mothership.commands[:services] }

      describe "metadata" do
        describe "command" do
          subject { command }
          its(:description) { should eq "List your services" }
          it { expect(Mothership::Help.group(:services)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has no required arguments" do
            should eq([])
          end
        end

        describe "inputs" do
          subject { command.inputs }
          it "has the expected inputs" do
            subject.keys.should =~ [:name, :service, :marketplace, :plan, :provider, :version, :app, :full, :space]
          end
        end
      end

      describe "listing services" do
        let(:global) { {:color => false} }
        let(:inputs) { {} }
        let(:given) { {} }
        let(:client) do
          build(:client).tap do |client|
            client.stub(:current_space => current_space, :service_instances => service_instances)
          end
        end
        let(:app) { build(:app) }

        let(:service_plan) { build(:service_plan, :service => build(:service, :version => "service_version", :provider => "provider")) }
        let(:service_binding) { build(:service_binding, :app => app) }
        let(:service1) { build(:service_instance, :service_plan => service_plan, :service_bindings => [service_binding]) }

        let(:service_instances) { [service1] }
        let(:current_space) { build(:space, :name => "the space") }

        subject do
          capture_output { Mothership.new.invoke(:services, inputs, given, global) }
        end

        before do
          stub_client_and_precondition
          client.stub(:service_bindings).and_return([service_binding])
        end

        it "produces a table of services" do
          subject
          stdout.rewind
          output = stdout.read

          expect(output).to match /Getting services in the space.*OK/

          expect(output).to match /name\s+service\s+provider\s+version\s+plan\s+bound apps/
          expect(output).to match /service-instance-.+?\s+  # name
        service-.*?\s+                                  # service
        provider.*?\s+                                  # provider
        service_version\s+                              # version
        service-plan-.*?\s+                             # plan
        app-name-\d+\s+                                         # bound apps
        /x

        end

        context 'when given --marketplace argument' do
          it 'lists services on the target' do
            client.stub(:services => Array.new(3) { build(:service) })
            cf %W[services --marketplace]
            expect(output).to say("Getting services... OK")
            expect(output).to say(/service\s+version\s+provider\s+plans\s+description/)
          end
        end
      end
    end
  end
end
