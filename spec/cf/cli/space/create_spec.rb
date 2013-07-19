require "spec_helper"

module CF
  module Space
    describe Create do
      let(:client) { build(:client) }
      before { stub_client_and_precondition }

      describe "metadata" do
        let(:command) { Mothership.commands[:create_space] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Create a space in an organization" }
          it { expect(Mothership::Help.group(:spaces)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([
              {:type => :optional, :value => nil, :name => :name},
              {:type => :optional, :value => nil, :name => :organization}
            ])
          end
        end
      end

      describe "running the command" do
        let(:new_space) { build(:space) }
        let(:organization) { build(:organization, :spaces => [new_space]) }

        before do
          client.stub(:space).and_return(new_space)
          new_space.stub(:create!)
          new_space.stub(:add_manager)
          new_space.stub(:add_developer)
          new_space.stub(:add_auditor)
          CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
          CF::Populators::Organization.any_instance.stub(:choices).and_return([organization])
        end

        context "when --target is given" do
          subject { cf %W[create-space #{new_space.name} --target] }

          it "switches them to the new space" do
            mock_invoke :target, :organization => organization, :space => new_space
            subject
          end
        end

        context "when --target is NOT given" do
          subject { cf %W[create-space #{new_space.name}] }

          it "tells the user how they can switch to the new space" do
            subject
            expect(output).to say("Space created!\n\ncf switch-space #{new_space.name}    # targets new space")
          end
        end
      end
    end
  end
end
