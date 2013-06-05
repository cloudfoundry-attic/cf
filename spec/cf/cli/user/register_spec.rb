require "spec_helper"

module CF
  module User
    describe Register do
      let(:client) { build(:client) }

      before do
        stub_client_and_precondition
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:register] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Create a user and log in" }
          it { expect(Mothership::Help.group(:admin, :user)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "have the correct commands" do
            should eq [
              {:type => :optional, :value => nil, :name => :email}
            ]
          end
        end
      end

      describe "#register" do
        let(:email) { "a@b.com" }
        let(:password) { "password" }
        let(:verify_password) { password }
        let(:force) { false }
        let(:login) { false }
        let(:score) { :strong }

        before do
          client.stub(:register)
          client.base.stub(:password_score) { score }
        end

        subject { cf %W[register --email #{email} --password #{password} --verify #{verify_password} --#{bool_flag(:login)} --#{bool_flag(:force)}] }

        context "when the passwords dont match" do
          let(:verify_password) { "other_password" }

          it { should eq 1 }

          it "fails" do
            subject
            expect(error_output).to say("Passwords do not match.")
          end

          it "doesn't print out the score" do
            subject
            expect(output).to_not say("strength")
          end

          it "doesn't log in or register" do
            client.should_not_receive(:register)
            dont_allow_invoke
            subject
          end

          context "and the force flag is passed" do
            let(:force) { true }

            it "doesn't verify the password" do
              client.should_receive(:register).with(email, password)
              subject
              expect(error_output).to_not say("Passwords do not match.")
            end
          end
        end

        context "when the password is good or strong" do
          it { should eq 0 }

          it "prints out the password score" do
            subject
            expect(stdout.string).to include "Your password strength is: strong"
          end

          it "registers the user" do
            client.should_receive(:register).with(email, password)
            subject
          end

          context "and the login flag is true" do
            let(:login) { true }

            it "logs in" do
              described_class.any_instance.should_receive(:invoke).with(:login, :username => email, :password => password)
              subject
            end
          end

          context "and the login flag is false" do
            it "doesn't log in" do
              described_class.any_instance.should_not_receive(:invoke)
              subject
            end
          end
        end

        context "when the password is weak" do
          let(:score) { :weak }
          let(:login) { true }

          it { should eq 1 }

          it "prints out the password score" do
            subject
            expect(error_output).to say("Your password strength is: weak")
          end

          it "doesn't register" do
            client.should_not_receive(:register).with(email, password)
            subject
          end

          it "doesn't log in" do
            dont_allow_invoke :login
            subject
          end
        end

        context "when arguments are not passed in the command line" do
          subject { cf %W[register --no-force --no-login] }

          it "asks for the email, password and confirm password" do
            should_ask("Email") { email }
            should_ask("Password", anything) { password }
            should_ask("Confirm Password", anything) { verify_password }
            subject
          end
        end
      end
    end
  end
end
