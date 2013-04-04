require "spec_helper"
require "webmock/rspec"
require "cf/cli/populators/organization"

describe CF::Populators::Organization do
  stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

  describe "#populate_and_save!" do
    let(:tokens_file_path) { "~/.cf/tokens.yml" }
    let(:user) { stub! }
    let(:organizations) do
      [
        fake(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user]),
        fake(:organization, :guid => "organization-id-2")
      ]
    end
    let(:organization) { organizations.first }
    let(:client) { fake_client :organizations => organizations }

    let(:input) { {:organization => organization} }
    let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }
    let(:populator) { populator = CF::Populators::Organization.new(Mothership::Inputs.new(nil, nil, input)) }

    before do
      stub(client).current_user { user }
      stub(client).organization { organization }
      stub(client).current_organization { organization }
      any_instance_of(described_class) do |instance|
        stub(instance).client { client }
      end

      write_token_file({:organization => "organization-id-1"})
    end

    subject do
      capture_output { populator.populate_and_save! }
    end

    it "updates the client with the new organization" do
      write_token_file({:organization => "organization-id-2"})
      any_instance_of(described_class) do |instance|
        stub.proxy(instance).client
      end
      populator.client.current_organization.guid.should == "organization-id-2"

      subject

      populator.client.current_organization.guid.should == "organization-id-1"
    end

    it "returns the organization" do
      subject.should == organization
    end

    context "with an organization in the input" do
      let(:input) { {:organization => organization} }
      before { write_token_file({:organization => "organization-id-2"}) }

      it "uses that organization" do
        subject.should == organization
      end

      it "should not reprompt for organization" do
        dont_allow_ask("Organization", anything)
        subject
      end

      it "sets the organization in the token file" do
        subject
        expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
      end
    end

    context "without an organization in the input" do
      let(:input) { {} }

      context "with an organization in the config file" do
        it "should not reprompt for organization" do
          dont_allow_ask("Organization", anything)
          subject
        end

        it "sets the organization in the token file" do
          subject
          expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
        end

        context "but that organization doesn't exist anymore (not valid)" do
          before { stub(organization).users { raise CFoundry::APIError } }

          it "asks the user for an organization" do
            mock_ask("Organization", anything) { organization }
            subject
          end
        end
      end

      context "without an organization in the config file" do
        before { write_token_file({}) }

        it "prompts for the organization" do
          mock_ask("Organization", anything) { organization }
          subject
        end

        it "sets the organization in the token file" do
          mock_ask("Organization", anything) { organization }

          subject
          expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
        end

        context "when the user has no organizations" do
          let(:client) { fake_client :organizations => [] }

          it "tells the user to create one by raising a UserFriendlyError" do
            expect { subject }.to raise_error(CF::UserFriendlyError, /There are no organizations/)
          end
        end
      end
    end
  end
end