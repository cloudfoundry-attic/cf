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
        stub(subject).random_helper_url { "caldecott" }
        stub(client).app { app }
        stub(client).current_space { space }
        stub(client).domains { [fake(:domain, :owning_organization => fake(:organization)), domain] }
      end

      it "adds a new route to caldecott app" do
        mock(app).create_route(:domain => domain, :host => host, :space => space)

        subject.send("push_helper", "this is a token")
      end
    end
  end
end
