require "spec_helper"
require "webmock/rspec"

describe CF::Start::Target do
  before do
    stub_client_and_precondition
  end

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

    context "when the user is authenticated and has an organization" do
      let(:user) { stub! }
      let(:organization) { fake(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user], :spaces => [space]) }
      let(:space) { fake(:space, :name => "Staging", :guid => "space-id-2", :developers => [user]) }
      let(:client) { fake_client :organizations => [organization], :token => CFoundry::AuthToken.new("bearer some-access-token") }

      before do
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
            any_instance_of(CFoundry::V2::Client) do |cli|
              stub(cli).info { raise CFoundry::TargetRefused, "foo" }
            end

            subject
            expect(error_output).to say("Target refused connection.")
          end
        end

        context "when the uri is malformed" do
          it "shows a pretty error message" do
            any_instance_of(CFoundry::V2::Client) do |cli|
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

        it "calls use a PopulateTarget to ensure that an organization and space is set" do
          mock(CF::Populators::Target).new(is_a(Mothership::Inputs)) { mock!.populate_and_save! }
          run_command
        end

        it "prints out the space from the updated client" do
          any_instance_of(CF::Populators::Target, :populate_and_save! => true)
          stub(client).current_space { space }

          run_command
          expect(output).to say("space: #{space.name}")
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
