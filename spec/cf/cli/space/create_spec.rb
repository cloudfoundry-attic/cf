require 'spec_helper'
require "cf/cli/space/create"

describe CF::Space::Create do
  describe 'metadata' do
    let(:command) { Mothership.commands[:create_space] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Create a space in an organization" }
      it { expect(Mothership::Help.group(:spaces)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([
          { :type => :optional, :value => nil, :name => :name },
          { :type => :optional, :value => nil, :name => :organization }
        ])
      end
    end
  end

  describe "running the command" do
    let(:new_space) { fake :space, :name => new_name }
    let(:new_name) { "some-new-name" }

    let(:spaces) { [new_space] }
    let(:organization) { fake(:organization, :spaces => spaces) }

    let(:client) { fake_client(:current_organization => organization, :spaces => spaces) }

    before do
      stub(client).space { new_space }
      stub(new_space).create!
      stub(new_space).add_manager
      stub(new_space).add_developer
      stub(new_space).add_auditor
      any_instance_of described_class do |cli|
        stub(cli).client { client }

        stub(cli).check_logged_in
        stub(cli).check_target
        any_instance_of(CF::Populators::Organization, :populate_and_save! => organization)
      end
    end

    context "when --target is given" do
      subject { cf %W[create-space #{new_space.name} --target] }

      it "switches them to the new space" do
        mock_invoke :target, :organization => organization,
          :space => new_space
        subject
      end
    end

    context "when --target is NOT given" do
      subject { cf %W[create-space #{new_space.name}] }

      it "tells the user how they can switch to the new space" do
        subject
        expect(output).to say("Space created! Use switch-space #{new_space.name} to target it.")
      end
    end
  end
end
