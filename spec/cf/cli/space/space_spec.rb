require 'spec_helper'
require 'stringio'

describe CF::Space::Space do
  let(:apps) { fake_list(:app, 2) }
  let(:domains) { fake_list(:domain, 2) }
  let(:services) { fake_list(:service_instance, 2) }
  let!(:space_1) { fake(:space, :name => "some_space_name", :apps => apps, :service_instances => services, :domains => domains) }
  let(:spaces) { [space_1] }
  let(:organization) { fake(:organization, :name => "Spacey Org", :spaces => spaces) }
  let(:client) { fake_client(:spaces => spaces, :current_organization => organization) }

  before do
    any_instance_of described_class do |cli|
      stub(cli).client { client }
      stub(cli).check_logged_in
      stub(cli).check_target
      any_instance_of(CF::Populators::Organization, :populate_and_save! => organization)
      any_instance_of(CF::Populators::Space, :populate_and_save! => space_1)
    end
  end

  context "with --quiet" do
    subject { cf %W[space some_space_name --quiet] }

    it "shows only the name" do
      subject
      expect(stdout.read).to eq("some_space_name\n")
    end
  end

  context "with --no-quiet" do
    subject { cf %W[space some_space_name --no-quiet] }

    before { subject }

    it "shows the space's name" do
      expect(stdout.read).to include("some_space_name:")
    end

    it "shows the space's org" do
      expect(stdout.read).to include("organization: Spacey Org")
    end

    it "shows apps" do
      expect(stdout.read).to include("apps: #{apps.first.name}, #{apps.last.name}")
    end

    it "shows services" do
      expect(stdout.read).to include("services: #{services.first.name}, #{services.last.name}")
    end

    it "shows domains" do
      expect(stdout.read).to include("domains: #{domains.first.name}, #{domains.last.name}")
    end
  end
end
