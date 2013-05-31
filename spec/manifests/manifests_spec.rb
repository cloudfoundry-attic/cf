require "spec_helper"

describe CFManifests do
  let(:inputs_hash) { {} }
  let(:given_hash) { {} }
  let(:global_hash) { {} }
  let(:inputs) { Mothership::Inputs.new(nil, nil, inputs_hash, given_hash, global_hash) }

  let(:cmd) do
    manifest = CF::App::Push.new(nil, inputs)
    manifest.extend CFManifests
    manifest.stub(:client) { client }
    manifest
  end

  let(:target_base) { "some-cloud.com" }

  let(:foo) { fake(:app, :name => "foo") }
  let(:bar) { fake(:app, :name => "bar") }
  let(:baz) { fake(:app, :name => "baz") }
  let(:xxx) { fake(:app, :name => "xxx") }
  let(:yyy) { fake(:app, :name => "yyy") }

  let(:client) do
    fake_client :apps => [foo, bar, baz, xxx, yyy]
  end

  let(:manifest_file) { "/abc/manifest.yml" }

  before do
    cmd.stub(:target_base) { target_base }

    cmd.stub(:manifest) { manifest }
    cmd.stub(:manifest_file) { manifest_file }
  end

  describe "#find_apps" do
    subject { cmd.find_apps(nil) }

    context "when there is no manifest file" do
      before { stub(cmd).manifest { nil } }
      it { should eq [] }
    end
  end

  describe "#create_manifest_for" do
    let(:app) {
      fake :app,
        :memory => 2048,
        :total_instances => 2,
        :command => "ruby main.rb",
        :buildpack => "git://example.com/foo.git",
        :routes => [
          fake(:route,
               :host => "some-app-name",
               :domain => fake(:domain, :name => target_base))
        ],
        :service_bindings => [
          fake(
            :service_binding,
            :service_instance =>
              fake(
                :service_instance,
                :name => "service-1",
                :service_plan =>
                  fake(
                    :service_plan,
                    :name => "P200",
                    :service => fake(:service))))
        ]
    }

    subject { cmd.create_manifest_for(app, "some-path") }

    its(["name"]) { should eq app.name }
    its(["memory"]) { should eq "2G" }
    its(["instances"]) { should eq 2 }
    its(["path"]) { should eq "some-path" }
    its(["url"]) { should eq "some-app-name.${target-base}" }
    its(["command"]) { should eq "ruby main.rb" }
    its(["buildpack"]) { should eq "git://example.com/foo.git" }

    it "contains the service information" do
      expect(subject["services"]).to be_a Hash

      services = subject["services"]
      app.service_bindings.each do |b|
        service = b.service_instance

        expect(services).to include service.name

        info = services[service.name]

        plan = service.service_plan
        offering = plan.service

        { "plan" => plan.name,
          "label" => offering.label,
          "provider" => offering.provider,
          "version" => offering.version
        }.each do |attr, val|
          expect(info).to include attr
          expect(info[attr]).to eq val
        end
      end
    end

    context "when there is no url" do
      let(:app) {
        fake :app,
          :memory => 2048,
          :total_instances => 2
      }

      its(["url"]) { should eq "none" }
    end

    context "when there is no command" do
      let(:app) {
        fake :app,
          :memory => 2048,
          :total_instances => 2
      }

      it { should_not include "command" }
    end

    context "when there are no service bindings" do
      let(:app) {
        fake :app,
          :memory => 2048,
          :total_instances => 2
      }

      it { should_not include "services" }
    end
  end

  describe "#setup_services" do
    let(:service_bindings) { [] }
    let(:app) { fake :app, :service_bindings => service_bindings }

    before do
      dont_allow_ask(anything, anything)
    end

    context "when services are defined in the manifest" do
      let(:info) {
        { :services => { "service-1" => { :label => "mysql", :plan => "100" } } }
      }

      let(:service_1) { fake(:service_instance, :name => "service-1") }

      let(:plan_100) { fake :service_plan, :name => "100" }

      let(:mysql) {
        fake(
          :service,
          :label => "mysql",
          :provider => "core",
          :service_plans => [plan_100])
      }

      let(:service_instances) { [] }

      let(:client) {
        fake_client :services => [mysql], :service_instances => service_instances
      }

      context "and the services exist" do
        let(:service_instances) { [service_1] }

        context "and are already bound" do
          let(:service_bindings) { [fake(:service_binding, :service_instance => service_1)] }

          it "does neither create nor bind the service again" do
            dont_allow(cmd).invoke :create_service, anything
            dont_allow(cmd).invoke :bind_service, anything
            cmd.send(:setup_services, app, info)
          end
        end

        context "but are not bound" do
          it "does not create the services" do
            dont_allow(cmd).invoke :create_service, anything
            stub(cmd).invoke :bind_service, anything
            cmd.send(:setup_services, app, info)
          end

          it "binds the service" do
            mock(cmd).invoke :bind_service, :app => app, :service => service_1
            cmd.send(:setup_services, app, info)
          end
        end
      end

      context "and the services do not exist" do
        it "creates the services" do
          mock(cmd).invoke :create_service, :app => app,
            :name => service_1.name, :offering => mysql, :plan => plan_100
          dont_allow(cmd).invoke :bind_service, anything
          cmd.send(:setup_services, app, info)
        end
      end
    end

    context "when there are no services defined" do
      let(:info) { {} }

      it "does not ask anything" do
        cmd.send(:setup_services, app, info)
      end
    end
  end

  describe "#apps_in_manifest" do
    let(:foo_hash) { { :name => "foo", :path => "/abc/foo" } }
    let(:bar_hash) { { :name => "bar", :path => "/abc/bar" } }
    let(:baz_hash) { { :name => "baz", :path => "/abc/baz" } }

    let(:manifest) { { :applications => [foo_hash, bar_hash, baz_hash] } }

    subject { cmd.apps_in_manifest(inputs) }

    context "when no apps are passed" do
      let(:given_hash) { {} }

      its(:first) { should eq [] }
      its(:last) { should eq [] }
    end

    context "when app names are passed" do
      context "and all of them are in the manifest" do
        let(:given_hash) { { :apps => ["foo", "bar"] } }

        its(:first) { should eq [foo_hash, bar_hash] }
        its(:last) { should eq [] }
      end

      context "and one of them is in the manifest" do
        let(:given_hash) { { :apps => ["foo", "xxx"] } }

        its(:first) { should eq [foo_hash] }
        its(:last) { should eq ["xxx"] }
      end

      context "and none of them are in the manifest" do
        let(:given_hash) { { :apps => ["xxx", "yyy"] } }

        its(:first) { should eq [] }
        its(:last) { should eq ["xxx", "yyy"] }
      end
    end

    context "when apps are passed as paths" do
      context "and the paths are in the manifest" do
        let(:given_hash) { { :apps => ["/abc/foo"] } }

        its(:first) { should eq [foo_hash] }
        its(:last) { should eq [] }
      end

      context "and any path is not in the manifest" do
        let(:given_hash) { { :apps => ["/abc/xxx"] } }

        it "fails with a manifest-specific method (i.e. path not in manifest)" do
          expect { subject }.to raise_error(CF::UserError, /Path .+ is not present in manifest/)
        end
      end
    end
  end

  describe "#all_apps" do
    let(:applications) do
      [
        {:name => "foo", :path => "/abc"},
        {:name => "bar", :path => "/abc"},
        {:name => "baz", :path => "/abc/baz"}
      ]
    end

    let(:manifest) do
      { :applications => applications }
    end

    subject { cmd.all_apps }

    it "returns all of the apps described in the manifest, as hashes" do
      expect(subject).to eq applications
    end
  end

  describe "#current_apps" do
    let(:manifest) do
      {:applications => [
        {:name => "foo", :path => "/abc"},
        {:name => "bar", :path => "/abc"},
        {:name => "baz", :path => "/abc/baz"}
      ]}
    end

    subject { cmd.current_apps }

    it "returns the applications with the cwd as their path" do
      Dir.stub(:pwd) { "/abc" }
      expect(subject).to eq [{ :name => "foo", :path => "/abc"}, { :name => "bar", :path => "/abc" }]
    end
  end
end
