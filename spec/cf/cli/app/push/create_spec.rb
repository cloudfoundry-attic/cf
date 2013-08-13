require "spec_helper"

module CF
  module App
    describe Create do
      let(:inputs) { {} }
      let(:given) { {} }
      let(:global) { {:color => false, :quiet => true} }

      let(:service_instances) { Array.new(5) { build(:managed_service_instance) } }
      let(:lucid64) { build(:stack, :name => "lucid64") }
      let(:client) { build(:client) }

      before do
        CF::CLI.any_instance.stub(:client).and_return(client)
        client.stub(:service_instances).and_return(service_instances)
        client.stub(:stacks).and_return([lucid64])
      end

      let(:path) { "some-path" }


      def setup_create
        command = Mothership.commands[:push]
        push_command = CF::App::Push.new(command)
        push_command.path = path
        push_command.input = Mothership::Inputs.new(command, push_command, inputs, given, global)
        push_command.extend CF::App::PushInteractions
        push_command
      end

      let(:push_command) { setup_create }

      describe "#get_inputs" do
        subject { push_command.get_inputs }

        let(:given) do
          {:name => "some-name",
            :instances => "1",
            :plan => "100",
            :memory => "1G",
            :command => "ruby main.rb",
            :buildpack => "git://example.com",
            :stack => "lucid64"
          }
        end

        context "when all the inputs are given" do
          its([:name]) { should eq "some-name" }
          its([:total_instances]) { should eq 1 }
          its([:space]) { should eq client.current_space }
          its([:command]) { should eq "ruby main.rb" }
          its([:memory]) { should eq 1024 }
          its([:stack]) { should eq lucid64 }
        end

        context "when the command is given" do
          context "and there is a Procfile in the application's root" do
            before do
              FakeFS.activate!
              Dir.mkdir(path)

              File.open("#{path}/Procfile", "w") do |file|
                file.write("this is a procfile")
              end
            end

            after do
              FakeFS.deactivate!
              FakeFS::FileSystem.clear
            end

            its([:command]) { should eq "ruby main.rb" }
          end
        end

        context "when certain inputs are not given" do
          it "asks for the name" do
            given.delete(:name)
            should_ask("Name") { "some-name" }
            subject
          end

          it "asks for the total instances" do
            given.delete(:instances)
            should_ask("Instances", anything) { 1 }
            subject
          end

          context "when the command is not given" do
            before { given.delete(:command) }

            it "defaults to nil" do
              expect(subject[:command]).to be_nil
            end

            describe "getting the start command" do
              before do
                FakeFS.activate!
                Dir.mkdir(path)
              end

              after do
                FakeFS.deactivate!
                FakeFS::FileSystem.clear
              end

              context "when there is a Procfile in the app's root" do
                before do
                  File.open("#{path}/Procfile", "w") do |file|
                    file.write("this is a procfile")
                  end
                end

                it "does not ask for a start command" do
                  dont_allow_ask("Startup command")
                  subject
                end
              end

              context "when there is no Procfile in the app's root" do
                it "is nil" do
                  expect(subject[:command]).to be_nil
                end
              end
            end
          end

          it "asks for the memory" do
            given.delete(:memory)

            memory_choices = %w(64M 128M 256M 512M 1G)
            push_command.stub(:memory_choices).and_return(memory_choices)

            should_ask("Memory Limit", anything) do |_, options|
              expect(options[:choices]).to eq memory_choices
              expect(options[:default]).to eq "256M"
              "1G"
            end

            subject
          end
        end
      end

      describe "#create_app" do
        before { dont_allow_ask }

        let(:app) { double(:app, :name => "some-app").as_null_object }
        let(:space) { double(:space, :name => "some-space") }

        let(:attributes) do
          {:name => "some-app",
            :total_instances => 2,
            :memory => 1024,
            :buildpack => "git://example.com"
          }
        end

        before do
          client.stub(:app).and_return(app)
          client.stub(:current_space).and_return(space)
        end

        subject { push_command.create_app(attributes) }

        context "when the user does not have permission to create apps" do
          it "fails with a friendly message" do
            app.stub(:create!).and_raise(CFoundry::NotAuthorized, "foo")

            expect { subject }.to raise_error(
              CF::UserError,
              "You need the Project Developer role in some-space to push.")
          end
        end

        context "with an invalid buildpack" do
          before do
            app.stub(:create!) do
              raise CFoundry::MessageParseError.new(
                "Request invalid due to parse error: Field: buildpack, Error: Value git@github.com:cloudfoundry/heroku-buildpack-ruby.git doesn't match regexp String /GIT_URL_REGEX/",
                1001)
            end
          end

          it "fails and prints a pretty message" do
            push_command.stub(:line).with(anything)
            expect { subject }.to raise_error(
              CF::UserError, "Buildpack must be a public git repository URI.")
          end
        end
      end

      describe "#map_url" do
        let(:app) { double(:app, :space => space, name: "app-name").as_null_object }
        let(:space) { double(:space, :domains => domains) }
        let(:domains) { [double(:domain, :name => "foo.com")] }
        let(:hosts) { [app.name] }

        subject { push_command.map_route(app) }

        it "asks for a subdomain with 'none' as an option" do
          should_ask("Subdomain", anything) do |_, options|
            expect(options[:choices]).to eq(hosts + %w(none))
            expect(options[:default]).to eq hosts.first
            hosts.first
          end

          stub_ask("Domain", anything) { domains.first }

          push_command.stub(:invoke)

          subject
        end

        it "asks for a domain with 'none' as an option" do
          stub_ask("Subdomain", anything) { hosts.first }

          should_ask("Domain", anything) do |_, options|
            expect(options[:choices]).to eq(domains + %w(none))
            expect(options[:default]).to eq domains.first
            domains.first
          end

          push_command.stub(:invoke)

          subject
        end

        it "maps the host and domain after both are given" do
          stub_ask("Subdomain", anything) { hosts.first }
          stub_ask("Domain", anything) { domains.first }

          push_command.should_receive(:invoke).with(:map,
            :app => app, :host => hosts.first,
            :domain => domains.first)

          subject
        end

        context "when 'none' is given as the host" do
          context "and a domain is provided afterwards" do
            it "invokes 'map' with an empty host" do
              should_ask("Subdomain", anything) { "none" }
              stub_ask("Domain", anything) { domains.first }

              push_command.should_receive(:invoke).with(:map,
                :host => "", :domain => domains.first, :app => app)

              subject
            end
          end
        end

        context "when 'none' is given as the domain" do
          it "does not perform any mapping" do
            stub_ask("Subdomain", anything) { "foo" }
            should_ask("Domain", anything) { "none" }

            push_command.should_not_receive(:invoke).with(:map, anything)

            subject
          end
        end

        context "when mapping fails" do
          before do
            should_ask("Subdomain", anything) { "foo" }
            should_ask("Domain", anything) { domains.first }

            push_command.should_receive(:invoke).with(:map,
              :host => "foo", :domain => domains.first, :app => app) do
              raise CFoundry::RouteHostTaken.new("foo", 1234)
            end
          end

          it "asks again" do
            push_command.stub(:line)

            should_ask("Subdomain", anything) { hosts.first }
            should_ask("Domain", anything) { domains.first }

            push_command.stub(:invoke)

            subject
          end

          it "reports the failure message" do
            push_command.should_receive(:line).with("foo")
            push_command.should_receive(:line)

            stub_ask("Subdomain", anything) { hosts.first }
            stub_ask("Domain", anything) { domains.first }

            push_command.stub(:invoke)

            subject
          end
        end
      end

      describe "#create_services" do
        let(:app) { build(:app, :client => client) }
        subject { push_command.create_services(app) }

        context "when forcing" do
          let(:inputs) { {:force => true} }

          it "does not ask to create any services" do
            dont_allow_ask("Create services for application?", anything)
            subject
          end

          it "does not create any services" do
            push_command.should_not_receive(:invoke).with(:create_service, anything)
            subject
          end
        end

        context "when not forcing" do
          let(:inputs) { {:force => false} }

          it "does not create the service if asked not to" do
            should_ask("Create services for application?", anything) { false }
            push_command.should_not_receive(:invoke).with(:create_service, anything)

            subject
          end

          it "asks again to create a service" do
            should_ask("Create services for application?", anything) { true }
            push_command.should_receive(:invoke).with(:create_service, {:app => app}, :plan => :interact).ordered

            should_ask("Create another service?", :default => false) { true }
            push_command.should_receive(:invoke).with(:create_service, {:app => app}, :plan => :interact).ordered

            should_ask("Create another service?", :default => false) { true }
            push_command.should_receive(:invoke).with(:create_service, {:app => app}, :plan => :interact).ordered

            should_ask("Create another service?", :default => false) { false }
            push_command.should_not_receive(:invoke).with(:create_service, anything).ordered

            subject
          end
        end
      end

      describe "#bind_services" do
        let(:app) { double(:app).as_null_object }

        subject { push_command.bind_services(app) }

        context "when forcing" do
          let(:global) { {:force => true, :color => false, :quiet => true} }

          it "does not ask to bind any services" do
            dont_allow_ask("Bind other services to application?", anything)
            subject
          end

          it "does not bind any services" do
            push_command.should_not_receive(:invoke).with(:bind_service, anything)
            subject
          end
        end

        context "when not forcing" do
          it "does not bind the service if asked not to" do
            should_ask("Bind other services to application?", anything) { false }
            push_command.should_not_receive(:invoke).with(:bind_service, anything)

            subject
          end

          it "asks again to bind a service" do
            bind_times = 3
            call_count = 0

            should_ask("Bind other services to application?", anything) { true }

            push_command.should_receive(:invoke).with(:bind_service, :app => app).exactly(bind_times).times do
              call_count += 1
              app.stub(:services).and_return(service_instances.first(call_count))
            end

            should_ask("Bind another service?", anything).exactly(bind_times).times do
              call_count < bind_times
            end

            subject
          end

          it "stops asking if there are no more services to bind" do
            bind_times = service_instances.size
            call_count = 0

            should_ask("Bind other services to application?", anything) { true }

            push_command.should_receive(:invoke).with(:bind_service, :app => app).exactly(bind_times).times do
              call_count += 1
              app.stub(:services).and_return(service_instances.first(call_count))
            end

            should_ask("Bind another service?", anything).exactly(bind_times-1).times { true }

            subject
          end

          context "when there are no services" do
            let(:service_instances) { [] }

            it "does not ask to bind anything" do
              dont_allow_ask
              subject
            end
          end
        end
      end

      describe "#start_app" do
        let(:app) { build(:app, :client => client) }
        subject { push_command.start_app(app) }

        context "when the start flag is provided" do
          let(:inputs) { {:start => true} }

          it "invokes the start command" do
            push_command.should_receive(:invoke).with(:start, :app => app)
            subject
          end
        end

        context "when the start flag is not provided" do
          let(:inputs) { {:start => false} }

          it "invokes the start command" do
            push_command.should_not_receive(:invoke).with(:start, anything)
            subject
          end
        end
      end
    end
  end
end
