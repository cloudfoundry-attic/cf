require "spec_helper"

module CF
  module Space
    describe Switch do
      let(:space_to_switch_to) { spaces.last }
      let(:spaces) { Array.new(3) { build(:space) } }
      let(:organization) { build(:organization, :spaces => spaces) }
      let(:client) { build(:client) }

      before do
        stub_client_and_precondition
        CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:switch_space] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Switch to a space" }
          it { expect(Mothership::Help.group(:spaces)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([{:type => :normal, :value => nil, :name => :name}])
          end
        end
      end

      subject { cf %W[--no-quiet switch-space #{space_to_switch_to.name} --no-color] }

      context "when the space exists" do
        before do
          Mothership.any_instance.should_receive(:invoke).with(:target, {:space => space_to_switch_to})
          client.stub(:spaces_by_name).with(space_to_switch_to.name).and_return([space_to_switch_to])
        end

        it "switches to that space" do
          subject
        end
      end

      context "when the space does not exist" do
        before { client.stub(:spaces_by_name).with(space_to_switch_to.name).and_return([]) }

        it_behaves_like "an error that gets passed through",
          :with_exception => CF::UserError,
          :with_message => /The space .* does not exist, please create the space first/
      end
    end
  end
end
