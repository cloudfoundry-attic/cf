require 'spec_helper'
require "cf/cli/space/delete"

describe CF::Space::Delete do
  describe 'metadata' do
    let(:command) { Mothership.commands[:delete_space] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Delete a space and its contents" }
      it { expect(Mothership::Help.group(:spaces)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([
          {:type => :splat, :value => nil, :name => :spaces}
        ])
      end
    end
  end

  describe "running the command" do
    let(:space) { fake :space, :name => "some_space_name" }
    let(:space_2) { fake :space, :name => "some_other_space_name" }
    let(:spaces) { [space, space_2] }
    let(:organization) { fake(:organization, :spaces => spaces, :name => "MyOrg") }

    let(:client) { fake_client(:current_organization => organization, :spaces => spaces) }

    subject { capture_output { cf %W[delete-space some_space_name some_other_space_name --quiet --force] } }

    before do
      any_instance_of described_class do |cli|
        stub(cli).client { client }

        stub(cli).check_logged_in
        stub(cli).check_target
        any_instance_of(CF::Populators::Organization, :populate_and_save! => organization)
      end
      stub(space).delete!
      stub(space_2).delete!
    end

    it "deletes all named spaces" do
      mock(space).delete!
      mock(space_2).delete!

      subject
    end

    context "without the force parameter" do
      subject { cf %W[delete-space some_space_name some_other_space_name --quiet] }
      it "confirms deletion of each space and deletes them" do
        mock(space).delete!
        dont_allow(space_2).delete!
        mock_ask("Really delete #{space.name}?", {:default => false}) { true }
        mock_ask("Really delete #{space_2.name}?", {:default => false}) { false }

        subject
      end
    end

    context "when deleting the current space" do
      it "warns the user what they've done" do
        stub(client).current_space { space }

        subject
        expect(output).to say("The space that you were targeting has now been deleted. Please use `cf target -s SPACE_NAME` to target a different one.")
      end
    end

    context "when a space fails to delete" do
      before do
        stub(space).delete! { raise CFoundry::AssociationNotEmpty.new("We don't delete children.", 10006) }
        subject
      end

      it "shows the error message" do
        expect(output).to say "We don't delete children."
      end

      it "informs the user of how to recursively delete" do
        expect(output).to say "If you want to delete the space along with all dependent objects, rerun the command with the '--recursive' flag."
      end
    end
  end
end
