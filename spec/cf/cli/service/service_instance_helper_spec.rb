require "spec_helper"

describe ServiceInstanceHelper do
  describe ".new" do
    let(:provided_instance) { build(:user_provided_service_instance) }
    let(:managed_instance) { build(:managed_service_instance) }

    it "returns a ManagedServiceInstanceHelper when the argument is a ManagedServiceInstance" do
      expect(ServiceInstanceHelper.new(managed_instance)).to be_a ManagedServiceInstanceHelper
    end

    it "returns a ManagedSerivceInstanceHelper when the argument is a ManagedServiceInstance" do
      expect(ServiceInstanceHelper.new(provided_instance)).to be_a UserProvidedServiceInstanceHelper
    end
  end
end

describe UserProvidedServiceInstanceHelper do
  let(:bindings) { [] }
  let(:instance) { build(:user_provided_service_instance, service_bindings: bindings) }
  subject(:helper) { UserProvidedServiceInstanceHelper.new(instance) }
  describe "matches" do
    it "returns true when 'user-provided' is the given label" do
      expect(helper.matches(service: "user-provided")).to eq true
    end

    it "returns false when 'user-provided' is not the given label" do
      expect(helper.matches(service: "a-different-label")).to eq false
    end

    it "returns true when a label is not given" do
      expect(helper.matches).to eq true
    end
  end

  its(:service_label) { should eq("user-provided") }
  its(:service_provider) { should eq("n/a") }
  its(:version) { should eq("n/a") }
  its(:plan_name) { should eq("n/a") }
  its(:name) { should eq instance.name }
  its(:service_bindings) { should eq instance.service_bindings }
end

describe ManagedServiceInstanceHelper do
  let(:label) { "some-label" }
  let(:provider) { "some-provider" }
  let(:version) { "some-version" }
  let(:plan_name) { "some-plan-name" }

  let(:service) { build(:service, label: label, provider: provider, version: version) }
  let(:plan) { build(:service_plan, service: service, name: plan_name) }
  let(:bindings) { [] }
  let(:instance) { build(:managed_service_instance, service_plan: plan, service_bindings: bindings) }
  subject(:helper) { ManagedServiceInstanceHelper.new(instance) }

  describe "matches" do
    it "returns true when no condition is specified" do
      expect(helper.matches).to eq(true)
    end

    context "filtering based on service" do
      it "returns true if the service label matches given service" do
        expect(helper.matches(service: label)).to eq(true)
      end

      it "returns false if the service label does not match given service" do
        expect(helper.matches(service: "a-different-label")).to eq(false)
      end
    end

    context "filtering based on service plan" do
      it "returns true if the plan name matches given plan" do
        expect(helper.matches(plan: plan_name)).to eq(true)
      end

      it "returns true if the plan name does not match given plan" do
        expect(helper.matches(plan: "some-other-plan-name")).to eq(false)
      end

      it "is case insensitive" do
        expect(helper.matches(plan: plan_name.upcase)).to eq(true)
      end
    end

    context "filtering based on provider" do
      it "returns true if the provider name matches given provider" do
        expect(helper.matches(provider: provider)).to eq(true)
      end

      it "returns true if the provider does not match given provider" do
        expect(helper.matches(provider: "a-different-provider")).to eq(false)
      end
    end

    context "filtering based on version" do
      it "returns true if the version matches given version" do
        expect(helper.matches(version: version)).to eq(true)
      end

      it "returns true if the version does not match given version" do
        expect(helper.matches(version: "a-different-version")).to eq(false)
      end
    end

    context "multiple filters" do
      it "returns true if the service instance matches all four parameters" do
        expect(helper.matches(service: label, plan: plan_name,
                              provider: provider, version: version)).to eq true
      end

      it "return false if any of the parameters does not match the attribute of the service instance" do
        expect(helper.matches(service: label, plan: plan_name,
                              provider: provider, version: "a-different-version")).to eq false
      end
    end

    context "with patterns for args" do
      it "returns true when service label matches the given glob" do
        expect(helper.matches(service: label.gsub(/.$/, "*"))).to eq(true)
      end

      it "returns false when the service label doesn not match the given glob" do
        expect(helper.matches(service: label + "_*")).to eq(false)
      end
    end
  end

  describe "service_label" do

    it "returns the label of instance's service offering" do
      expect(helper.service_label).to eq label
    end
  end

  describe "service_provider" do
    it "returns the provider of the instance's service offering" do
      expect(helper.service_provider).to eq provider
    end
  end

  describe "version" do
    it "returns the version of the instance's service offering" do
      expect(helper.version).to eq version
    end
  end

  describe "plan_name" do
    it "returns the name of the instance's service plan" do
      expect(helper.plan_name).to eq plan_name
    end
  end

  its(:name) { should eq instance.name }
  its(:service_bindings) { should eq instance.service_bindings }
end
