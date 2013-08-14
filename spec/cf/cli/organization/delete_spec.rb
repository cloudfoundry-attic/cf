require "spec_helper"

module CF
  module Organization
    describe Delete do
      describe "metadata" do
        let(:command) { Mothership.commands[:delete_org] }

        describe "command" do
          subject { command }
          it { expect(Mothership::Help.group(:organizations)).to include(subject) }
        end

        include_examples "inputs must have descriptions"
      end

      describe "running the command" do
        let(:organization) { build(:organization, :name => "MyOrg") }
        let(:organizations) { [organization] }

        let(:client) { build(:client) }

        subject { capture_output { cf %W[delete-org MyOrg --quiet --force] } }

        before do
          described_class.any_instance.stub(:client) { client }
          described_class.any_instance.stub(:check_logged_in)
          described_class.any_instance.stub(:check_target)
          CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
          organization.stub(:delete!).and_return(true)
          client.stub(:organizations).and_return(organizations)
          client.stub(:organizations_first_page).and_return(organizations)
        end

        context "without the force parameter" do
          subject { cf %W[delete-org MyOrg --quiet] }

          it "confirms deletion of the organization and deletes it" do
            organization.should_receive(:delete!).with(:recursive => false) { true }
            should_ask("Really delete #{organization.name}?", {:default => false}) { true }

            subject
          end
        end

        context "when deleting the last organization" do
          before do
            client.stub(:organizations_first_page).and_return([])
          end

          it "warns the user what they've done" do
            subject
            expect(output).to say("There are no longer any organizations.")
          end
        end

        context "when deleting the current organization" do
          let(:organizations) { [organization, build(:organization)] }

          before do
            client.stub(:current_organization).and_return(organization)
          end

          it "invalidates the old target / client" do
            described_class.any_instance.should_receive(:invalidate_client)
            subject
          end

          it "invokes the target command" do
            mock_invoke :target
            subject
          end
        end

        context "when an org fails to delete" do
          before do
            organization.stub(:delete!) { raise CFoundry::AssociationNotEmpty.new("We don't delete children.", 10006) }
            subject
          end

          it "shows the error message" do
            expect(output).to say "We don't delete children."
          end

          it "informs the user of how to recursively delete" do
            expect(output).to say "If you want to delete the organization along with all dependent objects, rerun the command with the '--recursive' flag."
          end

          it "returns a non-zero exit code" do
            @status.should_not == 0
          end
        end

        context "when deleting with --recursive" do
          subject { cf %W[delete-org MyOrg --recursive --force] }

          it "sends recursive true in its delete request" do
            organization.should_receive(:delete!).with(:recursive => true)
            subject
          end
        end
      end
    end
  end
end
