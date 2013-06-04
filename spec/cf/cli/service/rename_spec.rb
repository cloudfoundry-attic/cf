require "spec_helper"

describe CF::Service::Rename do
  let(:global) { { :color => false, :quiet => true } }
  let(:inputs) { {} }
  let(:given) { {} }
  let(:client) { fake_client }
  let(:service) {}
  let(:new_name) { "some-new-name" }

  subject { Mothership.new.invoke(:rename_service, inputs, given, global) }

  before do
    CF::CLI.any_instance.stub(:client).and_return(client)
  end

  describe "metadata" do
    let(:command) { Mothership.commands[:rename_service] }

    describe "command" do
      subject { command }
      its(:description) { should eq "Rename a service" }
      it { expect(Mothership::Help.group(:services, :manage)).to include(subject) }
    end

    include_examples "inputs must have descriptions"

    describe "arguments" do
      subject { command.arguments }
      it "has the correct argument order" do
        should eq([
          { :type => :optional, :value => nil, :name => :service },
          { :type => :optional, :value => nil, :name => :name }
        ])
      end
    end
  end

  context "when there are no services" do
    context "and a service is given" do
      let(:given) { { :service => "some-service" } }
      it { expect { subject }.to raise_error(CF::UserError, "Unknown service 'some-service'.") }
    end

    context "and a service is not given" do
      it { expect { subject }.to raise_error(CF::UserError, "No services.") }
    end
  end

  context "when there are services" do
    let(:client) { fake_client(:service_instances => services) }
    let(:services) { fake_list(:service_instance, 2) }
    let(:renamed_service) { services.first }

    context "when the defaults are used" do
      it "asks for the service and new name and renames" do
        should_ask("Rename which service?", anything) { renamed_service }
        should_ask("New name") { new_name }
        renamed_service.should_receive(:name=).with(new_name)
        renamed_service.should_receive(:update!)
        subject
      end
    end

    context "when no name is provided, but a service is" do
      let(:given) { { :service => renamed_service.name } }

      it "asks for the new name and renames" do
        dont_allow_ask("Rename which service?", anything)
        should_ask("New name") { new_name }
        renamed_service.should_receive(:name=).with(new_name)
        renamed_service.should_receive(:update!)
        subject
      end
    end

    context "when a service is provided and a name" do
      let(:inputs) { { :service => renamed_service, :name => new_name } }

      it "renames the service" do
        renamed_service.should_receive(:update!)
        subject
      end

      it "displays the progress" do
        mock_with_progress("Renaming to #{new_name}")
        renamed_service.should_receive(:update!)

        subject
      end

      context "and the name already exists" do
        it "fails" do
          renamed_service.should_receive(:update!) { raise CFoundry::ServiceInstanceNameTaken.new("Taken", 200) }
          expect { subject }.to raise_error(CFoundry::ServiceInstanceNameTaken)
        end
      end
    end
  end
end

