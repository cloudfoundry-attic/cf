require "spec_helper"

module CF
  module Populators
    describe Space do
      stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

      describe "#populate_and_save!" do
        let(:spaces) do
          [
            build(:space, :name => "Development", :guid => "space-id-1", :developers => [user]),
            build(:space, :name => "Staging", :guid => "space-id-2")
          ]
        end
        let(:space) { spaces.first }
        let(:user) { build(:user) }
        let(:client) { build(:client) }
        let(:organization) { build(:organization, :client => client, :name => "My Org", :guid => "organization-id-1", :users => [user], :spaces => spaces) }

        let(:tokens_file_path) { "~/.cf/tokens.yml" }
        let(:input_hash) { {:space => space} }
        let(:inputs) { Mothership::Inputs.new(nil, nil, input_hash) }
        let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }
        let(:populator) { CF::Populators::Space.new(inputs, organization) }

        before do
          client.stub(:current_user).and_return(user)
          described_class.any_instance.stub(:client).and_return(client)
        end

        def execute_populate_and_save
          capture_output { populator.populate_and_save! }
        end

        it "updates the client with the new space" do
          write_token_file({:space => "space-id-2"})
          described_class.any_instance.unstub(:client)
          populator.client.current_space.guid.should == "space-id-2"

          execute_populate_and_save

          populator.client.current_space.guid.should == "space-id-1"
        end

        it "returns the space" do
          execute_populate_and_save.should == space
        end

        describe "mothership input arguments" do
          let(:inputs) do
            Mothership::Inputs.new(nil, nil, input_hash).tap do |input|
              input.should_receive(:[]).with(:space, organization).and_return(space)
              input.stub(:[]).and_return(space)
            end
          end

          it "passes through extra arguments to the input call" do
            execute_populate_and_save
          end
        end

        context "with a space in the input" do
          let(:input_hash) { {:space => space} }
          before { write_token_file({:space => "space-id-2"}) }

          it "uses that space" do
            execute_populate_and_save.should == space
          end

          it "should not reprompt for space" do
            dont_allow_ask("Space", anything)
            execute_populate_and_save
          end

          it "sets the space in the token file" do
            execute_populate_and_save
            expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-1"
          end

          it "prints out that it is switching to that space" do
            execute_populate_and_save
            expect(output).to say("Switching to space #{space.name}")
          end
        end

        context "without a space in the input" do
          let(:input_hash) { {} }

          context "with a space in the config file" do
            before do
              write_token_file({:space => space.guid, :organization => organization.guid})
              client.stub(:space).and_return(space)
            end

            it "should not reprompt for space" do
              dont_allow_ask("Space", anything)
              execute_populate_and_save
            end

            it "sets the space in the token file" do
              execute_populate_and_save
              expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-1"
            end

            context "but that space doesn't exist anymore (not valid)" do
              before do
                space.stub(:developers).and_raise(CFoundry::APIError)
                organization.stub(:spaces).and_return(spaces)
              end

              it "asks the user for an space" do
                should_ask("Space", anything) { space }
                execute_populate_and_save
              end
            end
          end

          context "without a space in the config file" do
            context "when the user has spaces in that organization" do
              before do
                write_token_file({})
                organization.stub(:spaces).and_return(spaces)
              end

              it "prompts for the space" do
                should_ask("Space", anything) { space }
                execute_populate_and_save

                expect(output).to say("Switching to space #{space.name}")
              end

              it "sets the space in the token file" do
                should_ask("Space", anything) { space }

                execute_populate_and_save
                expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-1"
              end
            end

            context "when the user has no spaces in that organization" do
              before do
                write_token_file({})
                organization.stub(:spaces).and_return([])
              end

              it "warns the user they should create one" do
                execute_populate_and_save
                expect(output).to say("There are no spaces. You may want to create one with create-space.")
              end
            end
          end
        end
      end
    end
  end
end
