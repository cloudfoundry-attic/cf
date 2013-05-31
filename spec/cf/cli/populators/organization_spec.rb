require "spec_helper"

module CF
  module Populators
    describe Organization do
      stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

      describe "#populate_and_save!" do
        let(:tokens_file_path) { CF::TOKENS_FILE }
        let(:user) { build(:user) }
        let(:organizations) do
          [
            double(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user]),
            double(:organization, :name => "Other Org", :guid => "organization-id-2")
          ]
        end
        let(:organization) { organizations.first }
        let(:client) { fake_client :organizations => organizations }

        let(:input) { {:organization => organization} }
        let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }
        let(:populator) { populator = CF::Populators::Organization.new(Mothership::Inputs.new(nil, nil, input)) }

        before do
          client.stub(:current_user).and_return(user)
          client.stub(:organization).and_return(organization)
          client.stub(:current_organization).and_return(organization)
          client.stub(:target).and_return('https://api.some-domain.com')
          described_class.any_instance.stub(:client).and_return(client)

          write_token_file({:organization => "organization-id-1"})
        end

        subject do
          capture_output { populator.populate_and_save! }
        end

        it "updates the client with the new organization" do
          write_token_file({:organization => "organization-id-2"})
          described_class.any_instance.unstub(:client)
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

          it "prints out that it is switching to that organization" do
            subject
            expect(output).to say("Switching to organization #{organization.name}")
          end

          context "and a different organization and space in the token file" do
            let(:input) { {:organization => organizations.last} }

            before do
              write_token_file({:organization => "organization-id-1", :space => "should-be-removed"})
            end

            it "removes the space from the token file" do
              subject
              refreshed_tokens = YAML.load_file(File.expand_path(tokens_file_path))
              expect(refreshed_tokens["https://api.some-domain.com"][:space]).to be_nil
            end

          end

          context "and the same organization and a space in the token file" do
            before do
              write_token_file({:organization => "organization-id-1", :space => "should-not-be-removed"})
            end

            it "does not remove the space from the token file" do
              subject
              expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "should-not-be-removed"
            end
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
              before { organization.stub(:users).and_raise(CFoundry::APIError) }

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

              expect(output).to say("Switching to organization #{organization.name}")
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
  end
end
