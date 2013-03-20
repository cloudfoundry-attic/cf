require 'spec_helper'

describe CF::Start::Info do
  let(:services) { false }
  let(:all) { false }

  let(:client) do
    fake_client :services => fake_list(:service, 3), :token => CFoundry::AuthToken.new("bearer some-access-token")
  end

  let(:target_info) do
    { :description => "Some description",
      :version => 2,
      :support => "http://example.com"
    }
  end

  before do
    any_instance_of described_class do |cli|
      stub(cli).client { client }
    end
  end

  describe 'metadata' do
    let(:command) { Mothership.commands[:info] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Display information on the current target, user, etc." }
      it { expect(Mothership::Help.group(:start)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'flags' do
      subject { command.flags }

      its(["-s"]) { should eq :services }
      its(["-a"]) { should eq :all }
    end

    describe 'arguments' do
      subject { command.arguments }
      it { should be_empty }
    end
  end


  subject { cf %W[info --#{bool_flag(:services)} --#{bool_flag(:all)} --no-force --no-quiet] }

  context 'when given no flags' do
    it "displays target information" do
      mock(client).info { target_info }

      subject

      stdout.rewind
      expect(stdout.readline).to eq "Some description\n"
      expect(stdout.readline).to eq "\n"
      expect(stdout.readline).to eq "target: #{client.target}\n"
      expect(stdout.readline).to eq "  version: 2\n"
      expect(stdout.readline).to eq "  support: http://example.com\n"
    end
  end

  context 'when given --services' do
    let(:services) { true }

    it 'does not grab /info' do
      dont_allow(client).info
      subject
    end

    it 'lists services on the target' do
      subject

      stdout.rewind
      expect(stdout.readline).to match /Getting services.*OK/
      expect(stdout.readline).to eq "\n"
      expect(stdout.readline).to match /service\s+version\s+provider\s+plans\s+description/

      client.services.sort_by(&:label).each do |s|
        expect(stdout.readline).to match /#{s.label}\s+#{s.version}\s+#{s.provider}.+#{s.description}/
      end
    end
  end

  context 'when given --all' do
    let(:all) { true }

    it 'runs as --services' do
      mock(client).info { target_info }

      subject

      stdout.rewind
      expect(stdout.readline).to match /Getting services.*OK/
    end
  end

  context 'when there is no target' do
    let(:client) { nil }
    it_behaves_like "an error that gets passed through",
      :with_exception => CF::UserError,
      :with_message => "Please select a target with 'cf target'."
  end
end
