require "spec_helper"

describe CF::App::Rename do
  let(:global) { { :color => false, :quiet => true } }
  let(:inputs) { {} }
  let(:given) { {} }
  let(:client) { build(:client) }
  let(:app) {}
  let(:new_name) { "some-new-name" }

  before do
    CF::CLI.any_instance.stub(:client).and_return(client)
    CF::CLI.any_instance.stub(:precondition).and_return(nil)
  end

  subject { Mothership.new.invoke(:rename, inputs, given, global) }

  describe "metadata" do
    let(:command) { Mothership.commands[:rename] }

    describe "command" do
      subject { command }
      its(:description) { should eq "Rename an application" }
      it { expect(Mothership::Help.group(:apps, :manage)).to include(subject) }
    end

    include_examples "inputs must have descriptions"

    describe "arguments" do
      subject { command.arguments }
      it "has the correct argument order" do
        should eq([
          { :type => :optional, :value => nil, :name => :app },
          { :type => :optional, :value => nil, :name => :name }
        ])
      end
    end
  end

  context "when there are no apps" do
    before do
      client.stub(:apps).and_return([])
    end

    context "and an app is given" do
      let(:given) { { :app => "some-app" } }
      it { expect { subject }.to raise_error(CF::UserError, "Unknown app 'some-app'.") }
    end

    context "and an app is not given" do
      it { expect { subject }.to raise_error(CF::UserError, "No applications.") }
    end
  end

  context "when there are apps" do
    let(:apps) { [build(:app, :client => client), build(:app, :client => client)] }
    let(:renamed_app) { apps.first }

    before do
      client.stub(:apps).and_return(apps)
    end

    context "when the defaults are used" do
      it "asks for the app and new name and renames" do
        should_ask("Rename which application?", anything) { renamed_app }
        should_ask("New name") { new_name }
        renamed_app.should_receive(:name=).with(new_name)
        renamed_app.should_receive(:update!)
        subject
      end
    end

    context "when no name is provided, but a app is" do
      let(:given) { { :app => renamed_app.name } }

      it "asks for the new name and renames" do
        dont_allow_ask("Rename which application?", anything)
        should_ask("New name") { new_name }
        renamed_app.should_receive(:name=).with(new_name)
        renamed_app.should_receive(:update!)
        subject
      end
    end

    context "when an app is provided and a name" do
      let(:inputs) { { :app => renamed_app, :name => new_name } }

      it "renames the app" do
        renamed_app.should_receive(:update!)
        subject
      end

      it "displays the progress" do
        mock_with_progress("Renaming to #{new_name}")
        renamed_app.should_receive(:update!)

        subject
      end

      context "and the name already exists" do
        it "fails" do
          renamed_app.should_receive(:update!) { raise CFoundry::AppNameTaken.new("Bad Name", 404) }
          expect { subject }.to raise_error(CFoundry::AppNameTaken)
        end
      end
    end
  end
end
