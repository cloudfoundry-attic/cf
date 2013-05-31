require "spec_helper"

module CF
  module Space
    describe Create do
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
        let(:new_space) { fake(:space, :name => new_name) }
        let(:new_name) { "some-new-name" }

        let(:spaces) { [new_space] }
        let(:organization) { fake(:organization, :spaces => spaces) }

        let(:client) { fake_client(:current_organization => organization, :spaces => spaces) }

        before do
          client.stub(:space).and_return(new_space)
          new_space.stub(:create!)
          new_space.stub(:add_manager)
          new_space.stub(:add_developer)
          new_space.stub(:add_auditor)
          described_class.any_instance.stub(:client).and_return(client)
          described_class.any_instance.stub(:precondition).and_return(nil)
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
            expect(output).to say("Space created! Use `cf switch-space #{new_space.name}` to target it.")
          end
        end
      end
    end
  end
end
