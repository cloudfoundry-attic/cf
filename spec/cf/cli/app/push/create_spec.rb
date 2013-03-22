require 'spec_helper'
require 'fakefs/safe'

describe CF::App::Create do
  let(:inputs) { {} }
  let(:given) { {} }
  let(:global) { { :color => false, :quiet => true } }

  let(:service_instances) { fake_list(:service_instance, 5) }
  let(:lucid64) { fake :stack, :name => "lucid64" }

  let(:client) do
    fake_client(:service_instances => service_instances, :stacks => [lucid64])
  end

  before do
    any_instance_of(CF::CLI) do |cli|
      stub(cli).client { client }
    end
  end

  let(:path) { "some-path" }

  subject(:create) do
    command = Mothership.commands[:push]
    create = CF::App::Push.new(command)
    create.path = path
    create.input = Mothership::Inputs.new(command, create, inputs, given, global)
    create.extend CF::App::PushInteractions
    create
  end

  describe '#get_inputs' do
    subject { create.get_inputs }

    let(:given) do
      { :name => "some-name",
        :instances => "1",
        :plan => "p100",
        :memory => "1G",
        :command => "ruby main.rb",
        :buildpack => "git://example.com",
        :stack => "lucid64"
      }
    end

    context 'when all the inputs are given' do
      its([:name]) { should eq "some-name" }
      its([:total_instances]) { should eq 1 }
      its([:space]) { should eq client.current_space }
      its([:production]) { should eq true }
      its([:command]) { should eq "ruby main.rb" }
      its([:memory]) { should eq 1024 }
      its([:stack]) { should eq lucid64 }
    end

    context 'when the command is given' do
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

    context 'when certain inputs are not given' do
      it 'asks for the name' do
        given.delete(:name)
        mock_ask("Name") { "some-name" }
        subject
      end

      it 'asks for the total instances' do
        given.delete(:instances)
        mock_ask("Instances", anything) { 1 }
        subject
      end

      context 'when the command is not given' do
        before { given.delete(:command) }

        shared_examples 'an app that can have a custom start command' do
          it "asks for a start command with a default as 'none'" do
            mock_ask("Custom startup command", :default => "none") do
              "abcd"
            end

            expect(subject[:command]).to eq "abcd"
          end

          context "when the user enters 'none'" do
            it "has the command as nil" do
              stub_ask("Custom startup command", :default => "none") do
                "none"
              end

              expect(subject[:command]).to be_nil
            end
          end
        end

        include_examples 'an app that can have a custom start command'

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

            it 'does not ask for a start command' do
              dont_allow_ask("Startup command")
              subject
            end
          end

          context "when there is no Procfile in the app's root" do
            it 'asks for a start command' do
              mock_ask("Custom startup command", :default => "none")
              subject
            end
          end
        end
      end

      it 'asks for the memory' do
        given.delete(:memory)

        memory_choices = %w(64M 128M 256M 512M 1G)
        stub(create).memory_choices { memory_choices }

        mock_ask('Memory Limit', anything) do |_, options|
          expect(options[:choices]).to eq memory_choices
          expect(options[:default]).to eq "256M"
          "1G"
        end

        subject
      end
    end
  end

  describe '#create_app' do
    before { dont_allow_ask }

    let(:app) { fake(:app, :guid => nil) }
    let(:space) { fake(:space, :name => "some-space") }

    let(:attributes) do
      { :name => "some-app",
        :total_instances => 2,
        :production => false,
        :memory => 1024,
        :buildpack => "git://example.com"
      }
    end

    before do
      stub(client).app { app }
      stub(client).current_space { space }
    end

    subject { create.create_app(attributes) }

    it 'creates an app based on the resulting inputs' do
      mock(create).filter(:create_app, app) { app }

      mock(app).create!

      subject

      attributes.each do |key, val|
        expect(app.send(key)).to eq val
      end
    end

    context "when the user does not have permission to create apps" do
      it "fails with a friendly message" do
        stub(app).create! { raise CFoundry::NotAuthorized, "foo" }

        expect { subject }.to raise_error(
          CF::UserError,
          "You need the Project Developer role in some-space to push.")
      end
    end

    context "with an invalid buildpack" do
      before do
        stub(app).create! do
          raise CFoundry::MessageParseError.new(
            "Request invalid due to parse error: Field: buildpack, Error: Value git@github.com:cloudfoundry/heroku-buildpack-ruby.git doesn't match regexp String /GIT_URL_REGEX/",
            1001)
        end
      end

      it "fails and prints a pretty message" do
        stub(create).line(anything)
        expect { subject }.to raise_error(
          CF::UserError, "Buildpack must be a public git repository URI.")
      end
    end
  end

  describe '#map_url' do
    let(:app) { fake(:app, :space => space) }
    let(:space) { fake(:space, :domains => domains) }
    let(:domains) { [fake(:domain, :name => "foo.com")] }
    let(:hosts) { [app.name] }

    subject { create.map_route(app) }

    it "asks for a subdomain with 'none' as an option" do
      mock_ask('Subdomain', anything) do |_, options|
        expect(options[:choices]).to eq(hosts + %w(none))
        expect(options[:default]).to eq hosts.first
        hosts.first
      end

      stub_ask("Domain", anything) { domains.first }

      stub(create).invoke

      subject
    end

    it "asks for a domain with 'none' as an option" do
      stub_ask("Subdomain", anything) { hosts.first }

      mock_ask('Domain', anything) do |_, options|
        expect(options[:choices]).to eq(domains + %w(none))
        expect(options[:default]).to eq domains.first
        domains.first
      end

      stub(create).invoke

      subject
    end

    it "maps the host and domain after both are given" do
      stub_ask('Subdomain', anything) { hosts.first }
      stub_ask('Domain', anything) { domains.first }

      mock(create).invoke(:map,
        :app => app, :host => hosts.first,
        :domain => domains.first)

      subject
    end

    context "when 'none' is given as the host" do
      context "and a domain is provided afterwards" do
        it "invokes 'map' with an empty host" do
          mock_ask('Subdomain', anything) { "none" }
          stub_ask('Domain', anything) { domains.first }

          mock(create).invoke(:map,
            :host => "", :domain => domains.first, :app => app)

          subject
        end
      end
    end

    context "when 'none' is given as the domain" do
      it "does not perform any mapping" do
        stub_ask('Subdomain', anything) { "foo" }
        mock_ask('Domain', anything) { "none" }

        dont_allow(create).invoke(:map, anything)

        subject
      end
    end

    context "when mapping fails" do
      before do
        mock_ask('Subdomain', anything) { "foo" }
        mock_ask('Domain', anything) { domains.first }

        mock(create).invoke(:map,
            :host => "foo", :domain => domains.first, :app => app) do
          raise CFoundry::RouteHostTaken.new("foo", 1234)
        end
      end

      it "asks again" do
        stub(create).line

        mock_ask('Subdomain', anything) { hosts.first }
        mock_ask('Domain', anything) { domains.first }

        stub(create).invoke

        subject
      end

      it "reports the failure message" do
        mock(create).line "foo"
        mock(create).line

        stub_ask('Subdomain', anything) { hosts.first }
        stub_ask('Domain', anything) { domains.first }

        stub(create).invoke

        subject
      end
    end
  end

  describe '#create_services' do
    let(:app) { fake(:app) }
    subject { create.create_services(app) }

    context 'when forcing' do
      let(:inputs) { {:force => true} }

      it "does not ask to create any services" do
        dont_allow_ask("Create services for application?", anything)
        subject
      end

      it "does not create any services" do
        dont_allow(create).invoke(:create_service, anything)
        subject
      end
    end

    context 'when not forcing' do
      let(:inputs) { { :force => false } }

      it 'does not create the service if asked not to' do
        mock_ask("Create services for application?", anything) { false }
        dont_allow(create).invoke(:create_service, anything)

        subject
      end

      it 'asks again to create a service' do
        mock_ask("Create services for application?", anything) { true }
        mock(create).invoke(:create_service, { :app => app }, :plan => :interact).ordered

        mock_ask("Create another service?", :default => false) { true }
        mock(create).invoke(:create_service, { :app => app }, :plan => :interact).ordered

        mock_ask("Create another service?", :default => false) { true }
        mock(create).invoke(:create_service, { :app => app }, :plan => :interact).ordered

        mock_ask("Create another service?", :default => false) { false }
        dont_allow(create).invoke(:create_service, anything).ordered

        subject
      end
    end
  end

  describe '#bind_services' do
    let(:app) { fake(:app) }

    subject { create.bind_services(app) }

    context 'when forcing' do
      let(:global) { { :force => true, :color => false, :quiet => true } }

      it "does not ask to bind any services" do
        dont_allow_ask("Bind other services to application?", anything)
        subject
      end

      it "does not bind any services" do
        dont_allow(create).invoke(:bind_service, anything)
        subject
      end
    end

    context 'when not forcing' do
      it 'does not bind the service if asked not to' do
        mock_ask("Bind other services to application?", anything) { false }
        dont_allow(create).invoke(:bind_service, anything)

        subject
      end

      it 'asks again to bind a service' do
        bind_times = 3
        call_count = 0

        mock_ask("Bind other services to application?", anything) { true }

        mock(create).invoke(:bind_service, :app => app).times(bind_times) do
          call_count += 1
          stub(app).services { service_instances.first(call_count) }
        end

        mock_ask("Bind another service?", anything).times(bind_times) do
          call_count < bind_times
        end

        subject
      end

      it 'stops asking if there are no more services to bind' do
        bind_times = service_instances.size
        call_count = 0

        mock_ask("Bind other services to application?", anything) { true }

        mock(create).invoke(:bind_service, :app => app).times(bind_times) do
          call_count += 1
          stub(app).services { service_instances.first(call_count) }
        end

        mock_ask("Bind another service?", anything).times(bind_times - 1) { true }

        subject
      end

      context 'when there are no services' do
        let(:service_instances) { [] }

        it 'does not ask to bind anything' do
          dont_allow_ask
          subject
        end
      end
    end
  end

  describe '#start_app' do
    let(:app) { fake(:app) }
    subject { create.start_app(app) }

    context 'when the start flag is provided' do
      let(:inputs) { {:start => true} }

      it 'invokes the start command' do
        mock(create).invoke(:start, :app => app)
        subject
      end
    end

    context 'when the start flag is not provided' do
      let(:inputs) { {:start => false} }

      it 'invokes the start command' do
        dont_allow(create).invoke(:start, anything)
        subject
      end
    end
  end

  describe '#memory_choices' do
    let(:info) { {} }

    before do
      stub(client).info { info }
    end

    context "when the user has usage information" do
      let(:info) do
        { :usage => { :memory => 512 },
          :limits => { :memory => 2048 }
        }
      end

      it "asks for the memory with the ceiling taking the memory usage into account" do
        expect(subject.memory_choices).to eq(%w[64M 128M 256M 512M 1G])
      end
    end

    context "when the user does not have usage information" do
      let(:info) { {:limits => { :memory => 2048 } } }

      it "asks for the memory with the ceiling as their overall limit" do
        expect(subject.memory_choices).to eq(%w[64M 128M 256M 512M 1G 2G])
      end
    end
  end
end
