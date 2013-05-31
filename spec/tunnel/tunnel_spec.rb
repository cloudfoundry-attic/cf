require "spec_helper"

describe CFTunnel do
  # temporary solution until we get rspec-mocks! ;)
  class NullObject
    def initialize(id = "")
      @id = id
    end

    def ==(other)
      @id == other.id
    end

    def <=>(other)
      @id <=> other.id
    end

    def nil?
      true
    end

    def method_missing(*args)
      return self
    end
  end

  let(:client) { fake_client }
  let(:service) { NullObject.new }

  subject { CFTunnel.new(client, service) }

  describe "#open!" do
    describe "creating a route for caldecott" do
      let!(:app) { NullObject.new("app") }
      let!(:domain) { fake(:domain, :owning_organization => nil) }
      let!(:route) { fake(:route) }
      let!(:space) { fake(:space) }
      let(:host) { "caldecott" }

      before do
       subject.stub(:random_helper_url) { "caldecott" }
       client.stub(:app) { app }
       client.stub(:current_space) { space }
       client.stub(:domains) { [fake(:domain, :owning_organization => fake(:organization)), domain] }
      end

      it "adds a new route to caldecott app" do
        app.should_receive(:create_route).with(:domain => domain, :host => host, :space => space)

        subject.send("push_helper", "this is a token")
      end
    end
  end
end
