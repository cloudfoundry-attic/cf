require 'spec_helper'
require "cf/cli/space/switch"

describe CF::Space::Switch do
  let(:space_to_switch_to) { spaces.last }
  let(:spaces) { fake_list(:space, 3) }
  let(:organization) { fake(:organization, :spaces => spaces) }
  let(:client) { fake_client(:current_organization => organization, :spaces => spaces) }

  before do
    any_instance_of described_class do |cli|
      stub(cli).client { client }

      stub(cli).check_logged_in
      stub(cli).check_target
      any_instance_of(CF::Populators::Organization, :populate_and_save! => organization)
    end
  end

  describe 'metadata' do
    let(:command) { Mothership.commands[:switch_space] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Switch to a space" }
      it { expect(Mothership::Help.group(:spaces)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([{:type => :normal, :value => nil, :name => :name}])
      end
    end
  end

  subject { cf %W[--no-quiet switch-space #{space_to_switch_to.name} --no-color] }

  context "when the space exists" do
    before do
      any_instance_of(Mothership) do |m|
        mock(m).invoke(:target, {:space => space_to_switch_to})
      end
    end

    it "switches to that space" do
      subject
    end
  end

  context "when the space does not exist" do
    let(:space_to_switch_to) { fake(:space, :name => "unique-name") }

    it_behaves_like "an error that gets passed through",
      :with_exception => CF::UserError,
      :with_message => "The space unique-name does not exist, please create the space first."
  end
end
