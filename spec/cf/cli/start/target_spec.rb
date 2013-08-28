require "spec_helper"

module CF
  module Start
    describe Target do
      before do
        stub_client_and_precondition
      end

      let(:client) { build(:client).tap {|client| client.stub(:apps => [app]) } }
      let(:app) { build(:app) }

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
          let(:user) { build(:user).tap{ |u| u.stub(:email => "user@example.com") } }
          let(:organization) { build(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user], :spaces => [space]) }
          let(:space) { build(:space, :name => "Staging", :guid => "space-id-2", :developers => [user]) }

          before do
            client.stub(:logged_in?) { true }
            client.stub(:organizations) { [organization] }
            client.stub(:current_user) { user }
            client.stub(:organization) { organization }
            client.stub(:current_organization) { organization }
            described_class.any_instance.stub(:client) { client }
          end

          describe "switching the target" do
            let(:target) { "some-valid-target.com" }
            subject { cf ["target", target] }

            context "when the target is not valid" do
              before { WebMock.stub_request(:get, "https://#{target}/info").to_return(:body => "{}") }

              it "should still be able to switch to a valid target after that" do
                subject
              end
            end

            context "when the target is valid but the connection is refused" do
              it "shows a pretty error message" do
                CFoundry::V2::Client.any_instance.stub(:info) { raise CFoundry::TargetRefused, "foo" }

                subject
                expect(error_output).to say("Target refused connection.")
              end
            end

            context "when the uri is malformed" do
              it "shows a pretty error message" do
                CFoundry::V2::Client.any_instance.stub(:info) { raise CFoundry::InvalidTarget.new(target) }

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
              CF::Populators::Target.should_receive(:new) { double(:target, :populate_and_save! => true) }
              run_command
            end

            it "prints out the space from the updated client" do
              CF::Populators::Target.any_instance.stub(:populate_and_save!) { true }
              client.stub(:current_space) { space }

              run_command
              expect(output).to say("space: #{space.name}")
            end
          end

          describe "displaying the target (no args)" do
            it "prints things nicely" do
              client.stub(:current_space) { space }
              cf %W{target}
              expect(output).to say(<<-STR)
Target Information (where will apps be pushed):
  CF instance: #{client.target} (API version: 2)
  user: #{user.email}
  target app space: #{space.name} (org: #{organization.name})
              STR
            end
          end
        end
      end
    end
  end
end
