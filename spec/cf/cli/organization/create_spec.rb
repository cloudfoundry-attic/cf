require "spec_helper"

module CF
  module Organization
    describe Create do
      let(:client) { build(:client) }
      before { stub_client_and_precondition }

      describe "metadata" do
        subject(:command) { Mothership.commands[:create_org] }

        its(:description) { should == "Create an organization" }
        it { expect(Mothership::Help.group(:organizations)).to include(command) }
        its(:arguments) { should == [{type: :optional, value: nil, name: :name}] }

        include_examples "inputs must have descriptions"
      end

      describe "running the command" do
        let(:new_org) { build(:organization) }
        let(:current_user) { build(:user) }

        before do
          client.stub(organization: new_org)
          client.stub(current_user: current_user)

          @command_args = ["create-org", new_org.name]
        end

        context "when the organization already exists" do
          let(:existing_org) { build(:organization, name: new_org.name) }

          before do
            new_org.stub(:create!).and_raise(CFoundry::OrganizationNameTaken)
          end

          context "when --find-if-exists is given" do
            before { @command_args << "--find-if-exists" }
            before { client.stub(:organization_by_name).with(new_org.name).and_return(existing_org) }

            context "when --target is given" do
              before { @command_args << "--target" }

              it "switches them to the existing organization" do
                mock_invoke :target, organization: existing_org
                cf @command_args
              end
            end

            context "when --target is NOT given" do
              it "does not actively switch to the existing organization" do
                dont_allow_invoke :target
                cf @command_args
              end
            end
          end

          context "when --find-if-exists is NOT given" do
            before { @command_args << "--target" }

            context "when --target is given" do
              it "raises an exception" do
                expect { cf @command_args }.to raise_error(CFoundry::OrganizationNameTaken)
              end
            end

            context "when --target is NOT given" do
              it "raises an exception" do
                expect { cf @command_args }.to raise_error(CFoundry::OrganizationNameTaken)
              end
            end
          end
        end

        context "when the organization DOES NOT already exist" do
          before do
            new_org.stub(:create!)
          end

          context "when --find-if-exists is given" do
            before { @command_args << "--find-if-exists" }

            context "when --target is given" do
              before { @command_args << "--target" }

              it "switches them to the new organization" do
                mock_invoke :target, organization: new_org
                cf @command_args
              end
            end

            context "when --target is NOT given" do
              it "does not actively switch to the existing organization" do
                dont_allow_invoke :target
                cf @command_args
              end
            end
          end

          context "when --find-if-exists is NOT given" do
            context "when --target is given" do
              before { @command_args << "--target" }

              it "switches them to the new organization" do
                mock_invoke :target, organization: new_org
                cf @command_args
              end
            end

            context "when --target is NOT given" do
              it "does not actively switch to the existing organization" do
                dont_allow_invoke :target
                cf @command_args
              end
            end
          end
        end
      end
    end
  end
end
