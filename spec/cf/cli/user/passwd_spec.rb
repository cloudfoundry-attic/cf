require "spec_helper"

module CF
  module User
    describe Passwd do
      describe "metadata" do
        let(:command) { Mothership.commands[:passwd] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Update the current user's password" }
          it { expect(Mothership::Help.group(:admin, :user)).to include(subject) }
        end

        include_examples "inputs must have descriptions"
      end

      describe "#passwd" do
        let(:client) { build(:client) }
        let(:old_password) { "old" }
        let(:new_password) { "password" }
        let(:verify_password) { new_password }
        let(:score) { :strong }
        let(:guid) { random_string("my-object-guid") }
        let(:user) { build(:user) }

        before do
          stub_client_and_precondition
          client.stub(:logged_in?) { true }
          client.stub(:current_user) { user }
          client.stub(:register)
          client.base.stub(:password_score).with(new_password).and_return(score)
        end

        subject { cf %W[passwd --password #{old_password} --new-password #{new_password} --verify #{verify_password} --no-force --debug] }

        context "when the passwords dont match" do
          let(:verify_password) { "other_password" }

          it { should eq 1 }

          it "fails" do
            subject
            expect(stderr.string).to include "Passwords do not match."
          end

          it "doesn't print out the score" do
            subject
            expect(stdout.string).not_to include "strength"
          end

          it "doesn't log in or register" do
            user.should_not_receive(:change_password!)
            subject
          end
        end

        context "when the password is good or strong" do
          before do
            user.stub(:change_password!)
          end

          it { should eq 0 }

          it "prints out the password score" do
            subject
            expect(stdout.string).to include "Your password strength is: strong"
          end

          it "changes the password" do
            user.should_receive(:change_password!).with(new_password, old_password)
            subject
          end
        end

        context "when the password is weak" do
          let(:score) { :weak }

          it { should eq 1 }

          it "prints out the password score" do
            subject
            expect(stderr.string).to include "Your password strength is: weak"
          end

          it "doesn't change the password" do
            user.should_not_receive(:change_password!)
            subject
          end
        end
      end
    end
  end
end
