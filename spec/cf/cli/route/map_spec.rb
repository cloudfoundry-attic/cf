require "spec_helper"

module CF
  module Route
    describe Map do
      before do
        stub_client_and_precondition
      end

      let(:client) { fake_client(:apps => apps, :routes => routes) }

      let(:app) { fake(:app, :space => space, :name => "app-name") }
      let(:space) { fake(:space, :domains => space_domains).as_null_object }
      let(:domain) { fake(:domain, :name => "domain-name-1").as_null_object }

      let(:apps) { [app] }
      let(:routes) { [] }
      let(:domains) { [domain] }

      let(:space_domains) { domains }

      let(:host_name) { "some-host" }

      shared_examples "mapping the route to the app" do
        context "and the domain is mapped to the space" do
          let(:space_domains) { [domain] }

          context "and the route is mapped to the space" do
            let(:routes) { [route] }
            let(:route) do
              fake(:route, :space => space, :host => host_name,
                :domain => domain)
            end

            it "binds the route to the app" do
              app.should_receive(:add_route).with(route)
              subject
            end
          end

          context "and the route is not mapped to the space" do
            let(:new_route) { fake(:route) }

            before do
              client.stub(:route).and_return(new_route)
              app.stub(:add_route)
              new_route.stub(:create!)
            end

            it "indicates that it is creating a route" do
              subject
              expect(output).to say("Creating route #{host_name}.#{domain.name}")
            end

            it "creates the route in the app's space" do
              new_route.should_receive(:create!)
              subject
              expect(new_route.host).to eq host_name
              expect(new_route.domain).to eq domain
              expect(new_route.space).to eq space
            end

            it "indicates that it is binding the route" do
              subject
              expect(output).to say("Binding #{host_name}.#{domain.name} to #{app.name}")
            end

            it "binds the route to the app" do
              app.should_receive(:add_route).with(new_route)
              subject
            end
          end
        end
      end

      context "when an app is specified" do
        subject { cf(%W[map #{app.name} #{host_name} #{domain.name}]) }

        context "and the domain is not already mapped to the space" do
          let(:space_domains) { [] }

          it "indicates that the domain is invalid" do
            subject
            expect(error_output).to say("Unknown domain")
          end
        end

        include_examples "mapping the route to the app"
      end

      context "when an app is not specified" do
        let(:space_domains) { [domain] }
        let(:new_route) { double(:route).as_null_object }

        subject { cf %W[map --host #{host_name} #{domain.name}] }

        before { stub_ask("Which application?", anything) { app } }

        it "asks for an app" do
          client.stub(:route).and_return(new_route)
          app.stub(:add_route)
          new_route.stub(:create!)
          should_ask("Which application?", anything) { app }
          subject
        end

        include_examples "mapping the route to the app"
      end

      context "when a host is not specified" do
        let(:new_route) { build(:route) }

        subject { cf %W[map #{app.name} #{domain.name}] }

        before do
          client.stub(:route).and_return(new_route)
          app.stub(:add_route)
          new_route.stub(:create!)
        end

        it "creates a route with an empty string as its host" do
          new_route.should_receive(:create!)
          subject
          expect(new_route.host).to eq ""
        end
      end
    end
  end
end
