require "spec_helper"

module CF
  module Space
    describe Delete do
      let(:client) { build(:client) }
      before { stub_client_and_precondition }

      describe "metadata" do
        let(:command) { Mothership.commands[:delete_space] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Delete a space and its contents" }
          it { expect(Mothership::Help.group(:spaces)).to include(subject) }
        end

        include_examples "inputs must have descriptions"
      end

      describe "running the command" do
        let(:space) { build :space, :name => "some_space_name" }
        let(:organization) { build(:organization, :spaces => [space], :name => "MyOrg") }

        subject { capture_output { cf %W[delete-space some_space_name --quiet --force] } }

        before do
          CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
          organization.stub(:spaces_by_name).with("some_space_name").and_return([space])
          space.stub(:delete!)
        end

        context "without the force parameter when prompting" do
          subject { cf %W[delete-space some_space_name --quiet] }

          context "when the user responds 'y'" do
            it "deletes the space, exits cleanly" do
              space.should_receive(:delete!)
              should_ask("Really delete #{space.name}?", {:default => false}) { true }

              subject
              @status.should == 0
            end
          end

          context "when the user responds 'n'" do
            it "exits cleanly without deleting the space" do
              space.should_not_receive(:delete!)
              should_ask("Really delete #{space.name}?", {:default => false}) { false }

              subject
              @status.should == 0
            end
          end
        end

        context "when deleting the current space" do
          before do
            client.stub(:current_space) { space }
          end

          it "warns the user what they've done" do
            subject
            expect(output).to say("The space that you were targeting has now been deleted. Please use `cf target -s SPACE_NAME` to target a different one.")
          end

          context "when the current space has dependent objects" do
            before do
              space.stub(:delete!) { raise CFoundry::AssociationNotEmpty.new("We don't delete children.", 10006) }
            end

            it "does not print a success message" do
              subject
              expect(output).to_not say("The space that you were targeting has now been deleted")
            end
          end
        end

        context "when a space fails to delete" do
          before do
            space.stub(:delete!) { raise CFoundry::AssociationNotEmpty.new("We don't delete children.", 10006) }
            subject
          end

          it "shows the error message" do
            expect(output).to say "We don't delete children."
          end

          it "informs the user of how to recursively delete" do
            expect(output).to say "If you want to delete the space along with all dependent objects, rerun the command with the '--recursive' flag."
          end

          it "returns a non-zero exit code" do
            @status.should_not == 0
          end
        end

        context "when deleting with --recursive" do
          subject { cf %W[delete-space some_space_name --recursive --force] }

          it "sends recursive true in its delete request" do
            space.should_receive(:delete!).with(:recursive => true)
            subject
          end
        end
      end
    end
  end
end
