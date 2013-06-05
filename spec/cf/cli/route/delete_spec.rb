require 'spec_helper'

describe CF::Route::Delete do
  before do
    stub_client_and_precondition
    route.stub(:delete!)
  end

  let(:client) do
    build(:client).tap { |client| client.stub(:routes => [route]) }
  end
  let(:route) { build(:route, :host => host_name, :domain => domain) }
  let(:domain) { build(:domain, :name => domain_name) }
  let(:domain_name) { "some-domain.com" }
  let(:host_name) { "some-host" }
  let(:url) { "#{host_name}.#{domain_name}" }

  describe 'metadata' do
    let(:command) { Mothership.commands[:delete_route] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Delete a route" }
      it { expect(Mothership::Help.group(:routes)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([{:type => :normal, :value => nil, :name => :route}])
      end
    end
  end

  context "without the force parameter" do
    let(:command) { cf %W[delete-route #{url}] }

    it "prompts the user are they sure?" do
      should_ask("Really delete #{url}?", {:default => false}) { true }

      command
    end

    context "when the user responds 'y'" do
      before do
        stub_ask("Really delete #{url}?", {:default => false}) { true }
      end

      it "deletes the route" do
        route.should_receive(:delete!)
        command
      end

      it "exits cleanly" do
        command
        @status.should == 0
      end
    end

    context "when the user responds 'n'" do
      before do
        stub_ask("Really delete #{url}?", {:default => false}) { false }
      end

      it "does not delete the route" do
        route.should_not_receive(:delete!)
        command
      end

      it "exits cleanly" do
        command
        @status.should == 0
      end
    end
  end

  context "with the force parameter" do
    let(:command) { cf %W[delete-route #{url} --force] }

    it "deletes the route" do
      route.should_receive(:delete!)
      command
    end

    it "exits cleanly" do
      command
      @status.should == 0
    end
  end
end
