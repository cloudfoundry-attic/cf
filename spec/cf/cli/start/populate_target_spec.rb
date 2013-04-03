require "spec_helper"
require "webmock/rspec"

describe CF::Start::PopulateTarget do
  stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

  describe "#populate_and_save!" do
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
      let(:input) { {:organization => organization, :space => space} }

      before do
        stub(client).current_user { user }
        stub(client).organization { organization }
        stub(client).current_organization { organization }
        any_instance_of(described_class) do |instance|
          stub(instance).client { client }
        end
      end


      let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }
      before { write_token_file({:space => "space-id-1", :organization => "organization-id-1"}) }

      subject do
        mother_input = Mothership::Inputs.new(nil, nil, input)
        capture_output { CF::Start::PopulateTarget.new(mother_input, client).populate_and_save! }
      end

      context "with an organization and space in the config file" do
        before do
          write_token_file({:space => "space-id-1", :organization => "organization-id-1"})
        end

        it "should not reprompt for organization" do
          dont_allow_ask("Organization", anything)
          subject
        end

        it "sets the organization in the token file" do
          subject
          expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
        end

        it "sets the space param in the token file" do
          subject
          expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-2"
        end

        context "but that organization doesn't exist anymore (not valid)" do
          let(:input) { {:space => space} }
          before { stub(organization).users { raise CFoundry::APIError } }

          it "asks us for an organization" do
            mock_ask("Organization", anything) { organization }
            subject
          end
        end
      end

      context "with only an organization in the config file" do
        before { write_token_file({:organization => "organization-id-1"}) }

        context "with an space in the input" do
          it "does not ask for the space" do
            dont_allow_ask("Space", anything)
            subject
          end
        end

        context "without an space in the input" do
          let(:input) { {:organization => organization} }

          it "asks for the space" do
            mock_ask("Space", anything) { space }
            subject
          end

          it "sets the space in the token file" do
            stub_ask("Space", anything) { space }
            subject
            expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-2"
          end

          it "sets the space param in the token file" do
            stub_ask("Space", anything) { space }
            subject
            expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-2"
          end

          context "when the user has no spaces" do
            before { stub(organization).spaces { [] } }

            it "tells the user to create one" do
              subject
              expect(output).to say("There are no spaces")
              expect(output).to say("create one with")
            end
          end
        end
      end

      context "with only a space in the config file" do
        before { write_token_file({:space => "space-id-1"}) }

        context "with an organization in the input" do
          it "does not ask for the organization" do
            dont_allow_ask("Organization", anything)
            subject
          end
        end

        context "without an organization in the input" do
          let(:input) { {:space => space} }

          it "asks for the organization" do
            mock_ask("Organization", anything) { organization }
            subject
          end

          it "sets the organization in the token file" do
            stub_ask("Organization", anything) { organization }
            subject
            expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
          end

          it "sets the space param in the token file" do
            stub_ask("Organization", anything) { organization }
            subject
            expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-2"
          end

          context "when the user has no organizations" do
            let(:client) { fake_client :organizations => [], :token => CFoundry::AuthToken.new("bearer some-access-token") }

            it "tells the user to create one" do
              subject
              expect(output).to say("There are no organizations.")
              expect(output).to say("create one with")
            end
          end
        end
      end

      context "without an organization or space in the config file" do
        let(:organization_with_spaces) { organizations.first }
        let(:organization_without_spaces) { organizations.last }

        before { write_token_file({}) }

        context "without a space or organization in the token file" do
          let(:organization) { organization_with_spaces }
          context "with an organization in the input" do
            let(:input) { {:organization => organization} }
            it "prompts for the space" do
              mock_ask("Space", anything) { space }
              subject
            end
          end
        end

        context "when the user has no spaces in that organization" do
          let(:organization) { organization_without_spaces }
          let(:input) { {:organization => organization} }

          it "should tell the user to create one" do
            subject
            expect(output).to say("There are no spaces")
          end
        end
      end
    end
  end
end