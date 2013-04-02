require "spec_helper"
require "webmock/rspec"

command CF::Start::Target do
  let(:client) { fake_client :apps => [app] }
  let(:app) { fake :app }

  describe "metadata" do
    let(:command) { Mothership.commands[:target] }

    describe "command" do
      subject { command }
      its(:description) { should eq "Set or display the target cloud, organization, and space" }
      specify { expect(Mothership::Help.group(:start)).to include(subject) }
    end

    include_examples "inputs must have descriptions"

    describe "flags" do
      subject { command.flags }

      its(["-o"]) { should eq :organization }
      its(["--org"]) { should eq :organization }
      its(["-s"]) { should eq :space }
    end

    describe "arguments" do
      subject(:arguments) { command.arguments }
      it "have the correct commands" do
        expect(arguments).to eq [{:type => :optional, :value => nil, :name => :url}]
      end
    end
  end

  describe "running the command" do
    stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }
    let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }

    context "when the user is authenticated and has an organization" do
      let(:tokens_file_path) { "~/.cf/tokens.yml" }
      let(:organizations) {
        [fake(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user], :spaces => spaces),
          fake(:organization, :name => "My Org 2", :guid => "organization-id-2")]
      }
      let(:spaces) {
        [fake(:space, :name => "Development", :guid => "space-id-1"),
          fake(:space, :name => "Staging", :guid => "space-id-2", :developers => [user])]
      }

      let(:user) { stub! }
      let(:organization) { organizations.first }
      let(:space) { spaces.last }
      let(:client) do
        fake_client :organizations => organizations, :token => CFoundry::AuthToken.new("bearer some-access-token")
      end

      before do
        write_token_file({:space => "space-id-1", :organization => "organization-id-1"})
        stub(client).current_user { user }
        stub(client).organization { organization }
        stub(client).current_organization { organization }
        any_instance_of(described_class) do |instance|
          stub(instance).client { client }
        end
      end

      describe "switching the target" do
        let(:target) { "some-valid-target.com" }
        subject { cf ["target", target] }

        context "when the target is not valid" do
          before { WebMock.stub_request(:get, "http://#{target}/info").to_return(:body => "{}") }

          it "should still be able to switch to a valid target after that" do
            subject
          end
        end

        context "when the target is valid but the connection is refused" do
          it "shows a pretty error message" do
            any_instance_of(CFoundry::Client) do |cli|
              stub(cli).info { raise CFoundry::TargetRefused, "foo" }
            end

            subject
            expect(error_output).to say("Target refused connection.")
          end
        end

        context "when the uri is malformed" do
          it "shows a pretty error message" do
            any_instance_of(CFoundry::Client) do |cli|
              stub(cli).info { raise CFoundry::InvalidTarget.new(target) }
            end

            subject
            expect(error_output).to say("Invalid target URI.")
          end
        end
      end

      describe "switching the space" do
        def run_command
          cf %W[target -s #{space.name}]
        end

        context "without an organization in the config file" do
          before { write_token_file({:space => "space-id-1"}) }

          context "with an organization in the input" do
            it "does not ask for the organization" do
              dont_allow_ask("Organization", anything)
              cf %W[target -s #{space.name} -o some-org]
            end
          end

          context "without an organization in the input" do
            it "asks for the organization" do
              mock_ask("Organization", anything) { organization }
              run_command
            end

            it "sets the organization in the token file" do
              stub_ask("Organization", anything) { organization }
              run_command
              expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
            end

            it "sets the space param in the token file" do
              stub_ask("Organization", anything) { organization }
              run_command
              expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-2"
            end

            context "when the user has no organizations" do
              let(:client) { fake_client :organizations => [], :token => CFoundry::AuthToken.new("bearer some-access-token") }

              it "tells the user to create one" do
                run_command
                expect(output).to say("There are no organizations.")
                expect(output).to say("create one with")
              end
            end
          end
        end

        context "with an organization in the config file" do
          it "should not reprompt for organization" do
            dont_allow_ask("Organization", anything)
            run_command
          end

          it "sets the organization in the token file" do
            run_command
            expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
          end

          it "sets the space param in the token file" do
            run_command
            expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-2"
          end

          context "but that organization doesn't exist anymore (not valid)" do
            before { stub(organization).users { raise CFoundry::APIError } }

            it "asks us for an organization" do
              mock_ask("Organization", anything) { organization }
              run_command
            end
          end
        end
      end

      describe "switching the organization" do
        let(:organization_with_spaces) { organizations.first }
        let(:organization_without_spaces) { organizations.last }

        before { write_token_file({}) }

        subject { cf %W[target -o #{organization.name}] }

        context "without a space or organization in the token file" do
          let(:organization) { organization_with_spaces }
          context "with an organization in the input" do
            it "prompts for the space" do
              mock_ask("Space", anything) { space }
              subject
            end
          end
        end

        context "when the user has no spaces in that organization" do
          let(:organization) { organization_without_spaces }

          it "should tell the user to create one" do
            subject
            expect(output).to say("There are no spaces")
          end
        end
      end
    end

    context "when client is nil" do
      let(:client) { nil }
      subject { cf ["target"] }

      it 'prints an error' do
        subject
        expect(error_output).to say("No target has been specified.")
      end
    end
  end
end
