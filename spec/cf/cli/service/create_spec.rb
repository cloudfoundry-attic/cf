require "spec_helper"

module CF
  module Service
    describe Create do
      describe "metadata" do
        let(:command) { Mothership.commands[:create_service] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Create a service" }
          it { expect(Mothership::Help.group(:services, :manage)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([{:type => :optional, :value => nil, :name => :offering}, {:type => :optional, :value => nil, :name => :name}])
          end
        end
      end

      context "when there are services" do
        let(:service_plan) { fake(:service_plan, :name => "F20") }
        let(:selected_service) { fake(:service, :label => "Foo Service", :service_plans => [service_plan]) }
        let(:command) { Mothership.new.invoke(:create_service, params, {}) }
        let(:client) { fake_client(:services => services) }
        let(:params) { {} }

        before do
          CF::CLI.any_instance.stub(:client).and_return(client)
        end

        describe "when there is at least one service" do
          let(:services) { [selected_service] }

          it "asks for the service" do
            should_ask("What kind?", anything) { selected_service }
            should_ask("Name?", anything) { selected_service.label }
            should_ask("Which plan?", anything) { service_plan }
            CFoundry::V2::ServiceInstance.any_instance.stub(:create!)

            capture_output { command }
          end
        end

        describe "when there are more than one services" do
          let(:services) { [selected_service, fake(:service), fake(:service)] }

          it "asks for the service" do
            should_ask("What kind?", anything) { selected_service }
            should_ask("Name?", anything) { selected_service.label }
            should_ask("Which plan?", anything) { service_plan }
            CFoundry::V2::ServiceInstance.any_instance.stub(:create!)

            capture_output { command }
          end
        end

        describe "when the service plan is specified by an object, not a string" do
          let(:services) { [selected_service] }
          let(:params) { {
            :name => "my-service-name",
            :offering => selected_service,
            :plan => service_plan,
          } }

          it "creates the specified service" do
            CFoundry::V2::ServiceInstance.any_instance.should_receive(:service_plan=).with(service_plan)
            CFoundry::V2::ServiceInstance.any_instance.should_receive(:create!)
            capture_output { command }
          end
        end

        describe "when entering command line options" do
          let(:service_plan) { fake(:service_plan, :name => "f20") }
          let(:params) { {
            :name => "my-service-name",
            :offering => selected_service,
            :plan => "F20",
          } }
          let(:services) { [selected_service] }

          it "uses case insensitive match" do
            CFoundry::V2::ServiceInstance.any_instance.should_receive(:service_plan=).with(service_plan)
            CFoundry::V2::ServiceInstance.any_instance.should_receive(:create!)
            capture_output { command }
          end
        end
      end
    end
  end
end
