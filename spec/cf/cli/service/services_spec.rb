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
            subject.keys.should =~ [:name, :service, :plan, :provider, :version, :app, :full, :space]
          end
        end
      end

      describe "listing services" do
        let(:global) { {:color => false} }
        let(:inputs) { {} }
        let(:given) { {} }
        let(:client) { fake_client(:current_space => current_space, :service_instances => service_instances) }

        let(:service_plan) { fake(:service_plan, :service => fake(:service, :version => "service_version", :provider => "provider")) }
        let(:service1) { fake(:service_instance, :service_plan => service_plan) }

        let(:service_instances) { [service1] }
        let(:current_space) { fake(:space, :name => "the space") }

        subject do
          capture_output { Mothership.new.invoke(:services, inputs, given, global) }
        end

        before do
          CF::CLI.any_instance.stub(:client).and_return(client)
        end

        it "produces a table of services" do
          subject
          stdout.rewind
          output = stdout.read

          expect(output).to match /Getting services in the space.*OK/

          expect(output).to match /name\s+service\s+provider\s+version\s+plan\s+bound apps/
          expect(output).to match /service_instance-.+?\s+  # name
        service-.*?\s+                                  # service
        provider.*?\s+                                  # provider
        service_version\s+                              # version
        service_plan-.*?\s+                             # plan
        none\s+                                         # bound apps
        /x

        end
      end
    end
  end
end
