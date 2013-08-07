require "spec_helper"

module CF
  module Service
    describe Create do
      let(:client) { build(:client) }

      before do
        stub_client_and_precondition
      end

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
        let(:service_plan) { build(:service_plan, :name => "F20") }
        let(:selected_service) { build(:service, :label => "Foo Service", :service_plans => [service_plan]) }
        let(:command) { Mothership.new.invoke(:create_service, params, {}) }
        let(:params) { {} }

        before do
          client.stub(:services).and_return(services)
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
          let(:services) { [selected_service, build(:service), build(:service)] }

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
            CFoundry::V2::ManagedServiceInstance.any_instance.should_receive(:service_plan=).with(service_plan)
            CFoundry::V2::ManagedServiceInstance.any_instance.should_receive(:create!)
            capture_output { command }
          end
        end

        describe "when entering command line options" do
          let(:service_plan) { build(:service_plan, :name => "f20") }
          let(:params) { {
            :name => "my-service-name",
            :offering => selected_service,
            :plan => "F20",
          } }
          let(:services) { [selected_service] }

          it "uses case insensitive match" do
            CFoundry::V2::ManagedServiceInstance.any_instance.should_receive(:service_plan=).with(service_plan)
            CFoundry::V2::ManagedServiceInstance.any_instance.should_receive(:create!)
            capture_output { command }
          end
        end

        describe "when selecting the user-provided service" do
          let(:services) { [build(:service), build(:service)] }
          let(:user_provided_service) { build(:service, label: "user-provided")}

          before do
            client.stub(:services).and_return(services)
          end

          it "asks for an instance name and credentials" do
            should_ask("What kind?", hash_including(choices: include(has_label("user-provided")))) { user_provided_service }
            should_ask("Name?", anything) { "user-provided-service-name-1" }

            should_ask("What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)") { "host, port, user name" }
            should_print("'user name' is not a valid key")
            should_ask("What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)") { "host, port" }
            should_ask("host") { "example.com" }
            should_ask("port") { "8080" }
            mock_with_progress("Creating service user-provided-service-name-1")

            instance = client.user_provided_service_instance
            client.should_receive(:user_provided_service_instance).and_return(instance)
            instance.should_receive(:create!)

            capture_output { command }

            instance.credentials['host'].should == 'example.com'
            instance.credentials['port'].should == '8080'
          end

          # lame, i know
          context "when invoked from another command" do
            let(:params) { {
              :credentials => {"k" => "v"},
              :name => "service-name",
              :offering => UPDummy.new,
            } }

            it "creates a user-provided service" do
              instance = client.user_provided_service_instance
              client.should_receive(:user_provided_service_instance).and_return(instance)
              instance.should_receive(:create!)

              Mothership.new.invoke(:create_service, params, {})
            end
          end
        end
      end
    end
  end
end
