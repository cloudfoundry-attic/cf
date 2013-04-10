require 'spec_helper'

describe CF::User::Create do
  describe 'metadata' do
    let(:command) { Mothership.commands[:create_user] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Create a user" }
      it { expect(Mothership::Help.group(:admin, :user)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([
          { :type => :optional, :value => nil, :name => :email }
        ])
      end
    end
  end

  describe "running the command" do
    let(:client) { fake_client }
    let(:org) { fake(:organization) }
    let(:user) { fake(:user) }

    before do
      any_instance_of(described_class) { |cli| stub(cli).client { client } }
      stub(client).register
    end

    subject { cf %W[create-user --#{bool_flag(:force)}] }

    context "when the user is not logged in" do
      let(:force) { true }

      before do
        stub(client).logged_in? { false }
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
        stub(client).logged_in? { true }
        stub_ask("Email") { "some-angry-dude@example.com" }
        stub_ask("Password", anything) { "password1" }
        stub_ask("Verify Password", anything) { confirmation }
        stub(CF::Populators::Organization).new(instance_of(Mothership::Inputs)) { stub!.populate_and_save! { org } }

        stub(client).register("some-angry-dude@example.com", "password1") { user }
        stub(user).update!
      end

      it "ensures that an org is present" do
        mock(CF::Populators::Organization).new(instance_of(Mothership::Inputs)) { stub!.populate_and_save! { org } }
        subject
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
          mock(client).register("some-angry-dude@example.com", "password1") { user }
          stub(user).update!
          subject
        end

        it "adds the user to the current org" do
          stub(client).register(anything, anything) { user }
          mock(user).update!

          subject

          user.organizations.should == [org]
          user.managed_organizations.should == [org]
          user.audited_organizations.should == [org]
        end

      end
    end
  end
end
