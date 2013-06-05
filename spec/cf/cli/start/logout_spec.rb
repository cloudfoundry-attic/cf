require "spec_helper"

module CF
  module Start
    describe Logout do
      let(:client) { build(:client) }

      before do
        described_class.any_instance.stub(:client) { client }
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:logout] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Log out from the target" }
          it { expect(Mothership::Help.group(:start)).to include(subject) }
        end
      end

      describe "running the command" do
        subject { cf ["logout"] }

        context "when there is a target" do
          let(:info) { {client.target => "x", "abc" => "x"} }

          before do
            CF::CLI.any_instance.stub(:targets_info) { info }
            CF::CLI.any_instance.stub(:client_target) { client.target }
          end

          it "removes the target info from the tokens file" do
            expect {
              subject
            }.to change { info }.to("abc" => "x")
          end
        end

        context "when there is no target" do
          let(:client) { nil }
          it_behaves_like "an error that gets passed through",
            :with_exception => CF::UserError,
            :with_message => "Please select a target with 'cf target'."
        end
      end
    end
  end
end
