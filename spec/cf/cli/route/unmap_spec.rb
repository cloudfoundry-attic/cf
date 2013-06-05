require 'spec_helper'

describe CF::Route::Unmap do
  before do
    stub_client_and_precondition
  end

  let(:client) do
    build(:client).tap do |client|
      client.stub(:apps).and_return([app])
      client.stub(:apps_by_name).and_return([app])
    end
  end

  let(:app){ build(:app, :space => space, :name => "app-name") }
  let(:space) { build(:space, :name => "space-name", :domains => space_domains) }
  let(:domain) { build(:domain, :name => domain_name ) }
  let(:domain_name) { "some-domain.com" }
  let(:host_name) { "some-host" }
  let(:url) { "#{host_name}.#{domain_name}" }
  let(:space_domains) { [domain] }

  describe 'metadata' do
    let(:command) { Mothership.commands[:delete_service] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Delete a service" }
      it { expect(Mothership::Help.group(:services, :manage)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([{:type => :optional, :value => nil, :name => :service }])
      end
    end
  end

  context "when an app and a url are specified" do
    subject { cf %W[unmap #{url} #{app.name}] }

    context "when the given route is mapped to the given app" do
      let(:app) { build(:app, :space => space, :name => "app-name", :routes => [route]) }
      let(:route) { build(:route, :space => space, :host => host_name, :domain => domain) }

      it "unmaps the url from the app" do
        app.should_receive(:remove_route).with(route)
        subject
      end
    end

    context "when the given route is NOT mapped to the given app" do
      it "displays an error" do
        app.stub(:routes).and_return([])
        subject
        expect(error_output).to say("Unknown route")
      end
    end
  end

  context "when only an app is specified" do
    let(:other_route) { build(:route, :host => "abcd", :domain => domain) }
    let(:route) { build(:route, :host => "efgh", :domain => domain) }
    let(:app) { build(:app, :space => space, :routes => [route, other_route] )}

    subject { cf %W[unmap --app #{app.name}] }

    it "asks the user to select from the app's urls" do
      should_ask("Which URL?", anything) do |_, opts|
        expect(opts[:choices]).to eq [other_route, route]
        route
      end

      app.stub(:remove_route)

      subject
    end

    it "unmaps the selected url from the app" do
      stub_ask("Which URL?", anything) { route }
      app.should_receive(:remove_route).with(route)
      subject
    end
  end

  context "when an app is specified and the --all option is given" do
    let(:other_route) { build(:route, :host => "abcd", :domain => domain) }
    let(:route) { build(:route, :host => "efgh", :domain => domain) }
    let(:app) { build(:app, :routes => [route, other_route]) }

    subject { cf %W[unmap --all --app #{app.name}] }

    it "unmaps all routes from the given app" do
      app.should_receive(:remove_route).with(route)
      app.should_receive(:remove_route).with(other_route)
      subject
    end
  end

  context "when only a url is passed" do
    let(:route) { build(:route, :host => host_name, :domain => domain) }
    before { client.stub(:routes).and_return([route]) }

    subject { cf %W[unmap #{url}] }

    it "displays an error message" do
      subject
      expect(error_output).to say("Missing --app.")
    end
  end
end
