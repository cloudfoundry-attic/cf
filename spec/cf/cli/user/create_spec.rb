require "spec_helper"

module CF
  module User
    describe Create do
      describe "metadata" do
        let(:command) { Mothership.commands[:create_user] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Create a user" }
          it { expect(Mothership::Help.group(:admin, :user)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([
              {:type => :optional, :value => nil, :name => :email}
            ])
          end
        end
      end

      describe "running the command" do
        let(:client) { build(:client) }
        let(:org) { build(:organization) }
        let(:user) { build(:user) }

        before do
          stub_client
          client.stub(:register)
        end

        subject { cf %W[create-user --#{bool_flag(:force)}] }

        context "when the user is not logged in" do
          let(:force) { true }

          before do
            client.stub(:logged_in?) { false }
          end

          it "tells the user to log in" do
            subject
            expect(stderr.string).to include("Please log in")
          end
        end

        context "when the user is logged in" do
          let(:force) { false }
          let(:confirmation) { "password1" }

          before do
            client.stub(:logged_in?) { true }
            stub_ask("Email") { "some-angry-dude@example.com" }
            stub_ask("Password", anything) { "password1" }
            stub_ask("Verify Password", anything) { confirmation }

            CF::Populators::Organization.stub(:new) { double(:organization, :populate_and_save! => org) }
            client.stub(:register).with("some-angry-dude@example.com", "password1") { user }
            user.stub(:update!)
          end

          context "when the password does not match its confirmation" do
            let(:confirmation) { "wrong" }

            it "displays an error message" do
              subject
              expect(stderr.string).to include("Passwords don't match")
            end
          end

          context "when the password matches its confirmation" do
            it "creates a user" do
              client.should_receive(:register).with("some-angry-dude@example.com", "password1") { user }
              user.stub(:update!)
              subject
            end

            it "adds the user to the current org" do
              client.stub(:register).and_return(user)
              user.should_receive(:update!)

              subject

              user.organizations.should == [org]
              user.managed_organizations.should == [org]
              user.audited_organizations.should == [org]
            end
          end
        end
      end
    end
  end
end
