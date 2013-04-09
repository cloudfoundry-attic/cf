require "spec_helper"
require "webmock/rspec"
require "cf/cli/populators/space"

describe CF::Populators::Space do
  stub_home_dir_with { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

  describe "#populate_and_save!" do
    let(:tokens_file_path) { "~/.cf/tokens.yml" }
    let(:spaces) {
      [fake(:space, :name => "Development", :guid => "space-id-1", :developers => [user]),
        fake(:space, :name => "Staging", :guid => "space-id-2")]
    }

    let(:user) { stub! }
    let(:organization) { fake(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user], :spaces => spaces) }
    let(:space) { spaces.first }
    let(:client) do
      fake_client :organizations => [organization]
    end

    let(:input_hash) { {:space => space} }
    let(:inputs) { Mothership::Inputs.new(nil, nil, input_hash) }
    let(:tokens_yaml) { YAML.load_file(File.expand_path(tokens_file_path)) }
    let(:populator) { CF::Populators::Space.new(inputs, organization) }

    before do
      stub(client).current_user { user }
      stub(client).space { space }
      any_instance_of(described_class) do |instance|
        stub(instance).client { client }
      end

      write_token_file({:space => "space-id-1", :organization => "organization-id-1"})
    end

    subject do
      capture_output { populator.populate_and_save! }
    end

    it "updates the client with the new space" do
      write_token_file({:space => "space-id-2"})
      any_instance_of(described_class) do |instance|
        stub.proxy(instance).client
      end
      populator.client.current_space.guid.should == "space-id-2"

      subject

      populator.client.current_space.guid.should == "space-id-1"
    end

    it "returns the space" do
      subject.should == space
    end

    describe "mothership input arguments" do
      let(:inputs) do
        Mothership::Inputs.new(nil, nil, input_hash).tap do |input|
          mock(input).[](:space, organization) { space }
          stub(input).[](anything) { space }
        end
      end

      it "passes through extra arguments to the input call" do
        subject
      end
    end

    context "with a space in the input" do
      let(:input_hash) { {:space => space} }
      before { write_token_file({:space => "space-id-2"}) }

      it "uses that space" do
        subject.should == space
      end

      it "should not reprompt for space" do
        dont_allow_ask("Space", anything)
        subject
      end

      it "sets the space in the token file" do
        subject
        expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-1"
      end

      it "prints out that it is switching to that space" do
        subject
        expect(output).to say("Switching to space #{space.name}")
      end
    end

    context "without a space in the input" do
      let(:input_hash) { {} }

      context "with a space in the config file" do
        it "should not reprompt for space" do
          dont_allow_ask("Space", anything)
          subject
        end

        it "sets the space in the token file" do
          subject
          expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-1"
        end

        context "but that space doesn't exist anymore (not valid)" do
          before { stub(space).developers { raise CFoundry::APIError } }

          it "asks the user for an space" do
            mock_ask("Space", anything) { space }
            subject
          end
        end
      end

      context "without a space in the config file" do
        before { write_token_file({}) }

        it "prompts for the space" do
          mock_ask("Space", anything) { space }
          subject

          expect(output).to say("Switching to space #{space.name}")
        end

        it "sets the space in the token file" do
          mock_ask("Space", anything) { space }

          subject
          expect(tokens_yaml["https://api.some-domain.com"][:space]).to be == "space-id-1"
        end

        context "when the user has no spaces in that organization" do
          let(:organization) { fake(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user]) }

          it "tells the user to create one by raising a UserFriendlyError" do
            expect { subject }.to raise_error(CF::UserFriendlyError, /There are no spaces/)
          end
        end
      end
    end
  end
end
