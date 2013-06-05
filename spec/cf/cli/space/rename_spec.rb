require "spec_helper"

module CF
  module Space
    describe Rename do
      let(:client) { build(:client) }
      let(:spaces) { Array.new(3){ build(:space) } }
      let(:organization) { build(:organization, :spaces => spaces) }
      let(:new_name) { "some-new-name" }

      before do
        stub_client_and_precondition
        CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:rename_space] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Rename a space" }
          it { expect(Mothership::Help.group(:spaces)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([
              {:type => :optional, :value => nil, :name => :space},
              {:type => :optional, :value => nil, :name => :name}
            ])
          end
        end
      end

      context "when there are no spaces" do
        let(:spaces) { [] }

        before do
          client.stub(:spaces_by_name).with("some-invalid-space").and_return(spaces)
        end

        context "and a space is given" do
          subject { cf %W[rename-space --space some-invalid-space --no-force --no-quiet] }
          it "prints out an error message" do
            subject
            expect(stderr.string).to include "Unknown space 'some-invalid-space'."
          end
        end

        context "and a space is not given" do
          subject { cf %W[rename-space --no-force] }
          it "prints out an error message" do
            subject
            expect(stderr.string).to include "No spaces."
          end
        end
      end

      context "when there are spaces" do
        let(:renamed_space) { spaces.first }
        subject { cf %W[rename-space --no-force --no-quiet] }

        before do
          client.stub(:spaces_by_name).with(renamed_space.name).and_return(spaces)
        end

        context "when the defaults are used" do
          it "asks for the space and new name and renames" do
            should_ask("Rename which space?", anything) { renamed_space }
            should_ask("New name") { new_name }
            renamed_space.should_receive(:name=).with(new_name)
            renamed_space.should_receive(:update!)
            subject
          end
        end

        context "when no name is provided, but a space is" do
          subject { cf %W[rename-space --space #{renamed_space.name} --no-force] }

          it "asks for the new name and renames" do
            dont_allow_ask("Rename which space?", anything)
            should_ask("New name") { new_name }
            renamed_space.should_receive(:name=).with(new_name)
            renamed_space.should_receive(:update!)
            subject
          end
        end

        context "when a space is provided and a name" do
          subject { cf %W[rename-space --space #{renamed_space.name} --name #{new_name} --no-force] }

          it "renames the space" do
            renamed_space.should_receive(:update!)
            subject
          end

          it "displays the progress" do
            mock_with_progress("Renaming to #{new_name}")
            renamed_space.should_receive(:update!)

            subject
          end
        end
      end
    end
  end
end
