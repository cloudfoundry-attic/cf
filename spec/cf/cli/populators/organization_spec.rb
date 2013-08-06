require "spec_helper"

module CF
  module Populators
    describe Organization do
      stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

      describe "#populate_and_save!" do
        let(:tokens_file_path) { CF::TOKENS_FILE }
        let(:user) { build(:user) }
        let(:client) { build(:client) }
        let(:organizations) do
          [
            build(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user]),
            build(:organization, :name => "Other Org", :guid => "organization-id-2")
          ]
        end
        let(:organization) { organizations.first }

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

        def execute_populate_and_save
          capture_output { populator.populate_and_save! }
        end

        it "updates the client with the new organization" do
          write_token_file({:organization => "organization-id-2"})
          described_class.any_instance.unstub(:client)
          populator.client.current_organization.guid.should == "organization-id-2"

          execute_populate_and_save

          populator.client.current_organization.guid.should == "organization-id-1"
        end

        it "returns the organization" do
          execute_populate_and_save.should == organization
        end

        context "with an organization in the input" do
          let(:input) { {:organization => organization} }
          before { write_token_file({:organization => "organization-id-2"}) }

          it "uses that organization" do
            execute_populate_and_save.should == organization
          end

          it "should not reprompt for organization" do
            dont_allow_ask("Organization", anything)
            execute_populate_and_save
          end

          it "sets the organization in the token file" do
            execute_populate_and_save
            expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
          end

          it "prints out that it is switching to that organization" do
            execute_populate_and_save
            expect(output).to say("Switching to organization #{organization.name}")
          end

          context "and a different organization and space in the token file" do
            let(:input) { {:organization => organizations.last} }

            before do
              write_token_file({:organization => "organization-id-1", :space => "should-be-removed"})
            end

            it "removes the space from the token file" do
              execute_populate_and_save
              refreshed_tokens = YAML.load_file(File.expand_path(tokens_file_path))
              expect(refreshed_tokens["https://api.some-domain.com"][:space]).to be_nil
            end

          end

          context "and the same organization and a space in the token file" do
            before do
              write_token_file({:organization => "organization-id-1", :space => "should-not-be-removed"})
            end

            it "does not remove the space from the token file" do
              execute_populate_and_save
              expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "should-not-be-removed"
            end
          end

        end

        context "without an organization in the input" do
          let(:input) { {} }

          context "with an organization in the config file" do
            it "should not reprompt for organization" do
              dont_allow_ask("Organization", anything)
              execute_populate_and_save
            end

            it "sets the organization in the token file" do
              execute_populate_and_save
              expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
            end

            context "but that organization doesn't exist anymore (not valid)" do
              before do
                client.stub(:organizations_first_page).and_return({:results => organizations})
                organization.stub(:users).and_raise(CFoundry::APIError)
              end

              it "asks the user for an organization" do
                should_ask("Organization", anything) { organization }
                execute_populate_and_save
              end
            end
          end

          context "without an organization in the config file" do
            context "when the user has organizations" do
              before do
                client.stub(:organizations_first_page).and_return({:results => organizations})
                write_token_file({})
              end

              it "prompts for the organization" do
                should_ask("Organization", anything) { organization }
                execute_populate_and_save

                expect(output).to say("Switching to organization #{organization.name}")
              end

              it "sets the organization in the token file" do
                should_ask("Organization", anything) { organization }

                execute_populate_and_save
                expect(tokens_yaml["https://api.some-domain.com"][:organization]).to be == "organization-id-1"
              end
            end

            context "when the user has no organizations" do
              before do
                client.stub(:organizations_first_page).and_return({:results => []})
                write_token_file({})
              end

              it "warns the user they should create one" do
                execute_populate_and_save
                expect(output).to say("There are no organizations. You may want to create one with create-org.")
              end
            end

            context "when the user has too many organizations" do
              before do
                client.stub(:organizations_first_page).and_return({:results => organizations, :next_page => true})
                write_token_file({})
              end

              it "tells the user to set their target" do
                expect { execute_populate_and_save }.to raise_error(CF::UserFriendlyError, "Login successful. Too many organizations (>50) to list. Remember to set your target organization using 'target -o [ORGANIZATION]'.")
              end
            end
          end
        end
      end
    end
  end
end
