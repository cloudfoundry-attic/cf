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
              {type: :optional, value: nil, name: :name},
              {type: :optional, value: nil, name: :organization}
            ])
          end
        end
      end

      describe "running the command" do
        let(:new_space) { build(:space) }

        before do
          client.stub(space: new_space)
          CF::Populators::Organization.any_instance.stub(populate_and_save!: organization)

          @command_args = ["create-space", new_space.name]
        end

        context "when the space already exists" do
          let(:existing_space) { build(:space, name: new_space.name) }
          let(:organization) { build(:organization, spaces: [existing_space]) }
          let(:current_user) { build(:user) }

          before do
            client.stub(current_user: current_user)
            new_space.stub(:create!).and_raise(CFoundry::SpaceNameTaken)
          end
          
          context "when --find-if-exists is given" do
            before do
              @command_args << "--find-if-exists"
              client.stub(:space_by_name).with(new_space.name).and_return(existing_space)
              existing_space.stub(:add_manager).with(current_user)
              existing_space.stub(:add_developer).with(current_user)
            end

            context "when --target is given" do
              before { @command_args << "--target" }

              it "switches them to the existing space" do
                mock_invoke :target, organization: organization, space: existing_space
                cf @command_args
              end
            end

            context "when --target is NOT given" do
              it "tells the user how they can switch to the existing space" do
                cf @command_args
                expect(output).to say("Space already exists!\n\ncf switch-space #{existing_space.name}    # targets existing space")
              end
            end
          end

          context "when --find-if-exists is NOT given" do
            before { @command_args << "--target" }

            context "when --target is given" do
              it "raises an exception" do
                expect { cf @command_args }.to raise_error(CFoundry::SpaceNameTaken)
              end
            end

            context "when --target is NOT given" do
              it "raises an exception" do
                expect { cf @command_args }.to raise_error(CFoundry::SpaceNameTaken)
              end
            end
          end
        end

        context "when the space DOES NOT already exist" do
          let(:organization) { build(:organization, spaces: []) }

          before do
            new_space.stub(:create!)
            new_space.stub(:add_manager)
            new_space.stub(:add_developer)
            new_space.stub(:add_auditor)
          end          
          
          context "when --find-if-exists is given" do
            before { @command_args << "--find-if-exists" }

            context "when --target is given" do
              before { @command_args << "--target" }

              it "switches them to the new space" do
                mock_invoke :target, organization: organization, space: new_space
                cf @command_args
              end
            end

            context "when --target is NOT given" do
              it "tells the user how they can switch to the new space" do
                cf @command_args
                expect(output).to say("Space created!\n\ncf switch-space #{new_space.name}    # targets new space")
              end
            end
          end

          context "when --find-if-exists is NOT given" do
            context "when --target is given" do
              before { @command_args << "--target" }

              it "switches them to the new space" do
                mock_invoke :target, organization: organization, space: new_space
                cf @command_args
              end
            end

            context "when --target is NOT given" do
              it "tells the user how they can switch to the new space" do
                cf @command_args
                expect(output).to say("Space created!\n\ncf switch-space #{new_space.name}    # targets new space")
              end
            end
          end
        end
      end
    end
  end
end
