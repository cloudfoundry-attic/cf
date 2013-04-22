require 'spec_helper'
require "cf/cli/organization/delete"

describe CF::Organization::Delete do
  describe 'metadata' do
    let(:command) { Mothership.commands[:delete_org] }

    describe 'command' do
      subject { command }
      it { expect(Mothership::Help.group(:organizations)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'
  end

  describe "running the command" do
    let(:organization) { fake(:organization, :name => "MyOrg") }
    let(:organizations) { [organization] }

    let(:client) { fake_client(:current_organization => organization, :organizations => organizations) }

    subject { capture_output { cf %W[delete-org MyOrg --quiet --force] } }

    before do
      any_instance_of described_class do |cli|
        stub(cli).client { client }

        stub(cli).check_logged_in
        stub(cli).check_target
        any_instance_of(CF::Populators::Organization, :populate_and_save! => organization)
      end
      stub(organization).delete!
    end

    context "without the force parameter" do
      subject { cf %W[delete-org MyOrg --quiet] }
      it "confirms deletion of the organization and deletes it" do
        mock(organization).delete!
        mock_ask("Really delete #{organization.name}?", {:default => false}) { true }

        subject
      end
    end

    context "when deleting the last organization" do
      it "warns the user what they've done" do
        subject
        expect(output).to say("There are no longer any organizations.")
      end
    end

    context "when deleting the current organization" do
      let(:organizations) { [organization, fake(:organization)] }
      it "invalidates the old target / client" do
        any_instance_of(described_class) { |cli| mock(cli).invalidate_client }
        subject
      end

      it "invokes the target command" do
        mock_invoke :target
        subject
      end
    end

    context "when an org fails to delete" do
      before do
        stub(organization).delete! { raise CFoundry::AssociationNotEmpty.new("We don't delete children.", 10006) }
        subject
      end

      it "shows the error message" do
        expect(output).to say "We don't delete children."
      end

      it "informs the user of how to recursively delete" do
        expect(output).to say "If you want to delete the organization along with all dependent objects, rerun the command with the '--recursive' flag."
      end
    end

    context "when deleting with --recursive" do
      subject { cf %W[delete-org MyOrg --recursive --force] }

      it "sends recursive true in its delete request" do
        mock(organization).delete!(:recursive => true)
        subject
      end
    end
  end
end
