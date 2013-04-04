require 'spec_helper'

command CF::Start::Login do
  let(:client) { fake_client }

  describe 'metadata' do
    let(:command) { Mothership.commands[:login] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Authenticate with the target" }
      specify { expect(Mothership::Help.group(:start)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'flags' do
      subject { command.flags }

      its(["-o"]) { should eq :organization }
      its(["--org"]) { should eq :organization }
      its(["--email"]) { should eq :username }
      its(["-s"]) { should eq :space }
    end

    describe 'arguments' do
      subject(:arguments) { command.arguments }
      it 'have the correct commands' do
        expect(arguments).to eq [{:type => :optional, :value => :email, :name => :username}]
      end
    end
  end

  describe "running the command" do
    stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

    let(:auth_token) { CFoundry::AuthToken.new("bearer some-new-access-token", "some-new-refresh-token") }
    let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }
    let(:tokens_file_path) { '~/.cf/tokens.yml' }

    before do
      stub(client).login("my-username", "my-password") { auth_token }
      stub(client).login_prompts do
        {
          :username => ["text", "Username"],
          :password => ["password", "8-digit PIN"]
        }
      end

      stub_ask("Username", {}) { "my-username" }
      stub_ask("8-digit PIN", {:echo => "*", :forget => true}) { "my-password" }
      any_instance_of(CF::Populators::Target, :populate_and_save! => true)
    end

    subject { cf ["login"] }

    it "logs in with the provided credentials and saves the token data to the YAML file" do
      subject

      expect(tokens_yaml["https://api.some-domain.com"][:token]).to eq("bearer some-new-access-token")
      expect(tokens_yaml["https://api.some-domain.com"][:refresh_token]).to eq("some-new-refresh-token")
    end

    it "calls use a PopulateTarget to ensure that an organization and space is set" do
      mock(CF::Populators::Target).new(is_a(Mothership::Inputs)) { mock!.populate_and_save! }
      subject
    end

    context "when the user logs in with invalid credentials" do
      before do
        stub(client).login("my-username", "my-password") { raise CFoundry::Denied }
      end

      it "informs the user gracefully" do
        subject
        expect(output).to say("Authenticating... FAILED")
      end
    end

    context 'when there is no target' do
      let(:client) { nil }
      let(:stub_precondition?) { false }

      it "tells the user to select a target" do
        subject
        expect(error_output).to say("Please select a target with 'cf target'.")
      end
    end
  end
end
