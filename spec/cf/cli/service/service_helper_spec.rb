require 'spec_helper'

describe ServiceHelper do
  describe "#label" do
    it "returns the label for the service" do
      service = build(:service, label: 'mysql')
      helper = ServiceHelper.new(service)

      expect(helper.label).to eq('mysql')
    end
  end

  describe "#provider" do
    it "returns the provider for the service if it has one" do
      service = build(:service, provider: 'aws')
      helper = ServiceHelper.new(service)

      expect(helper.provider).to eq('aws')
    end

    it "returns n/a if it does not have a provider" do
      service = build(:service, provider: nil)
      helper = ServiceHelper.new(service)

      expect(helper.provider).to eq('n/a')
    end
  end

  describe "#version" do
    it "returns the version for the service if it has one" do
      service = build(:service, version: '3.11')
      helper = ServiceHelper.new(service)

      expect(helper.version).to eq('3.11')
    end

    it "returns n/a if it does not have a version" do
      service = build(:service, version: nil)
      helper = ServiceHelper.new(service)

      expect(helper.version).to eq('n/a')
    end
  end

  describe "#service_plans" do
    it "returns the plans for the service if it has one" do
      plans = [
        build(:service_plan, name: 'small'),
        build(:service_plan, name: 'large')
      ]
      service = build(:service, :service_plans => plans)
      helper = ServiceHelper.new(service)

      expect(helper.service_plans).to eq('small, large')
    end
  end

  describe "#description" do
    it "returns the plans for the service if it has one" do
      service = build(:service, :description => 'super awesome NoSQL NO DOWNTIME')
      helper = ServiceHelper.new(service)

      expect(helper.description).to eq('super awesome NoSQL NO DOWNTIME')
    end
  end
end
