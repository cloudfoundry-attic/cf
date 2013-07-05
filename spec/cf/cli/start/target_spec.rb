require "spec_helper"
require "cfoundry"

module CF
  module Start
    describe Target do
      before do
        stub_client
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
          let(:user) { build(:user) }
          let(:organization) do
            org = build(:organization, :name => "My Org", :guid => "organization-id-1", :users => [user], :spaces => [space, space])
            org.manifest[:metadata] = { :guid => org.guid }
            org
          end

          let(:other_organization) do
            org = build(:organization, :name => "My Other Org", :guid => "organization-id-2", :users => [user], :spaces => [space, space])
            org.manifest[:metadata] = {:guid => org.guid }
            org
          end

          let(:space) { build(:space, :name => "Staging", :guid => "space-id-2", :developers => [user]) }
          let(:spaces) { [space] }

          before do
            CF::Populators::Target.stub(:client).and_return(client)
            client.stub(:logged_in?) { true }
            client.base.stub(:organizations) { [organization.manifest, other_organization.manifest] }
            client.stub(:current_user) { user }
            client.current_organization = organization
            client.current_space = space
            CF::Populators::Space.any_instance.stub(:choices).and_return(spaces)
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

          describe "switching the organization" do

            # context "When invalid argument is provided" do
            #   before do
            #     cf %W[target -o invalid_org_name]
            #   end

            #   it "reports error"
            # end

            context "when valid argument is provided" do

              it "switches organization" do
                cf %W[target]
                expect(output).to say("organization: #{organization.name}")
                clear_output

                cf %W[target -o #{other_organization.name}]
                expect(output).to say("Switching to organization #{other_organization.name}")
                expect(output).to say("organization: #{other_organization.name}")
              end

              it "asks to select new space" do
                pending
                expect(output).to say("Space>")
              end

              it "prints new organization and space when 'cf target' is run"
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
  end
end
