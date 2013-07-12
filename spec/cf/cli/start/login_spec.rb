require "spec_helper"

describe CF::Start::Login do
  let(:client) { build(:client) }

  describe "metadata" do
    before do
      stub_client_and_precondition
    end

    let(:command) { Mothership.commands[:login] }

    describe "command" do
      subject { command }
      its(:description) { should eq "Authenticate with the target" }
      specify { expect(Mothership::Help.group(:start)).to include(subject) }
    end

    include_examples "inputs must have descriptions"

    describe "flags" do
      subject { command.flags }

      its(["-o"]) { should eq :organization }
      its(["--org"]) { should eq :organization }
      its(["--email"]) { should eq :username }
      its(["-s"]) { should eq :space }
    end

    describe "arguments" do
      subject { command.arguments }

      it "have the correct commands" do
        expect(subject).to eq [{
          :type => :optional,
          :value => :email,
          :name => :username
        }]
      end
    end
  end

  describe "running the command" do
    before { stub_client }

    stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

    before do
      client.stub(:login_prompts).and_return(
        :username => ["text",     "username-prompt"],
        :password => ["password", "password-prompt"],
        :passcode => ["password", "passcode-prompt"]
      )
    end

    def self.it_logs_in_user_with_credentials(expected_credentials)
      context "when there is a target" do
        before { stub_precondition }

        context "when user is successfully authenticated" do
          before { client.stub(:login).with(expected_credentials) { auth_token } }
          before { CF::Populators::Target.any_instance.stub(:populate_and_save!) }
          let(:auth_token) { CFoundry::AuthToken.new("bearer some-new-access-token", "some-new-refresh-token") }

          it "logs in with the provided credentials and saves the token data to the YAML file" do
            subject
            expect(tokens_yaml["https://api.some-domain.com"][:token]).to eq("bearer some-new-access-token")
            expect(tokens_yaml["https://api.some-domain.com"][:refresh_token]).to eq("some-new-refresh-token")
          end

          it "calls use a PopulateTarget to ensure that an organization and space is set" do
            CF::Populators::Target.should_receive(:new) { double(:target, :populate_and_save! => true) }
            subject
          end
        end

        context "when the user logs in with invalid credentials" do
          before do
            client
              .should_receive(:login)
              .with(expected_credentials)
              .exactly(3).times
              .and_raise(CFoundry::Denied)
          end

          it "informs the user gracefully about authentication failure" do
            subject
            expect(output).to say("Authenticating... FAILED")
          end

          it "does not save token data" do
            expect {
              subject
            }.to_not change { tokens_yaml["https://api.some-domain.com"] }
          end

          it "does not call PopulateTarget" do
            CF::Populators::Target.should_not_receive(:new)
            subject
          end
        end

        def tokens_yaml
          YAML.load_file(File.expand_path("~/.cf/tokens.yml"))
        end
      end

      context "when there is no target" do
        before { client.stub(:target) { nil } }

        it "tells the user to select a target" do
          subject
          expect(error_output).to say("Please select a target with 'cf target'.")
        end
      end
    end

    context "when user is trying to log in with username/password" do
      subject { cf ["login"] }

      before do
        stub_ask("username-prompt", {}) { "my-username" }
        stub_ask("password-prompt", {:echo => "*", :forget => true}) { "my-password" }
      end

      it_logs_in_user_with_credentials(
        :username => "my-username", :password => "my-password")
    end

    context "when user is trying to log in via sso" do
      subject { cf ["login", "--sso"] }

      before do
        stub_ask("username-prompt", {}) { "my-username" }
        stub_ask("passcode-prompt", {:echo => "*", :forget => true}) { "my-passcode" }
      end

      it_logs_in_user_with_credentials(
        :username => "my-username", :passcode => "my-passcode")
    end
  end
end
