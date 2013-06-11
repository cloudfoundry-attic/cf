require "spec_helper"

module CF
  module App
    describe Push do
      let(:global) { {:color => false, :quiet => true} }
      let(:inputs) { {} }
      let(:given) { {} }
      let(:path) { "somepath" }
      let(:client) { build(:client) }
      let(:push) { CF::App::Push.new(Mothership.commands[:push]) }

      before do
        CF::CLI.any_instance.stub(:client) { client }
        CF::CLI.any_instance.stub(:precondition) { nil }
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:push] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Push an application, syncing changes if it exists" }
          it { expect(Mothership::Help.group(:apps, :manage)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([{:type => :optional, :value => nil, :name => :name}])
          end
        end
      end

      describe "#sync_app" do
        let(:app) { build(:app, :client => client, :name => "app-name-1") }

        before do
          app.stub(:upload)
          app.changes = {}
        end

        subject do
          push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
          push.sync_app(app, path)
        end

        shared_examples "common tests for inputs" do |*args|
          context "when the new input is the same as the old" do
            type, input = args
            input ||= type

            let(:inputs) { {input => old} }

            it "does not update the app's #{type}" do
              push.should_not_receive(:line)
              app.should_not_receive(:update!)
              expect { subject }.not_to change { app.send(type) }
            end
          end
        end

        it "triggers the :push_app filter" do
          push.should_receive(:filter).with(:push_app, app) { app }
          subject
        end

        it "uploads the app" do
          app.should_receive(:upload).with(path)
          subject
        end

        context "when no inputs are given" do
          let(:inputs) { {} }

          it "should not update the app" do
            app.should_not_receive(:update!)
            subject
          end

          it "should not set memory on the app" do
            app.should_not_receive(:memory=)
            subject
          end
        end

        context "when memory is given" do
          let(:old) { 1024 }
          let(:new) { "2G" }
          let(:app) { build(:app, :memory => old) }
          let(:inputs) { {:memory => new} }

          it "updates the app memory, converting to megabytes" do
            push.stub(:line)
            app.should_receive(:update!)
            expect { subject }.to change { app.memory }.from(old).to(2048)
          end

          it "outputs the changed memory in human readable sizes" do
            push.should_receive(:line).with("Changes:")
            push.should_receive(:line).with("memory: 1G -> 2G")
            app.stub(:update!)
            subject
          end

          include_examples "common tests for inputs", :memory
        end

        context "when instances is given" do
          let(:old) { 1 }
          let(:new) { 2 }
          let(:app) { build(:app, :total_instances => old) }
          let(:inputs) { {:instances => new} }

          it "updates the app instances" do
            push.stub(:line)
            app.stub(:update!)
            expect { subject }.to change { app.total_instances }.from(old).to(new)
          end

          it "outputs the changed instances" do
            push.should_receive(:line).with("Changes:")
            push.should_receive(:line).with("total_instances: 1 -> 2")
            app.stub(:update!)
            subject
          end

          include_examples "common tests for inputs", :total_instances, :instances
        end

        context "when command is given" do
          let(:old) { "./start" }
          let(:new) { "./start foo " }
          let(:app) { build(:app, :command => old) }
          let(:inputs) { {:command => new} }

          it "updates the app command" do
            push.stub(:line)
            app.should_receive(:update!)
            expect { subject }.to change { app.command }.from("./start").to("./start foo ")
          end

          it "outputs the changed command in single quotes" do
            push.should_receive(:line).with("Changes:")
            push.should_receive(:line).with("command: './start' -> './start foo '")
            app.stub(:update!)
            subject
          end

          include_examples "common tests for inputs", :command
        end

        context "when restart is given" do
          let(:inputs) { {:restart => true, :memory => 4096} }

          before do
            CF::App::Base.any_instance.stub(:human_mb).and_return(0)
          end

          context "when the app is already started" do
            let(:app) { build(:app, :state => "STARTED") }

            it "invokes the restart command" do
              push.stub(:line)
              app.should_receive(:update!)
              push.should_receive(:invoke).with(:restart, :app => app)
              subject
            end

            context "but there are no changes" do
              let(:inputs) { {:restart => true} }

              it "invokes the restart command" do
                push.stub(:line)
                app.should_not_receive(:update!)
                push.should_receive(:invoke).with(:restart, :app => app)
                subject
              end
            end
          end

          context "when the app is not already started" do
            let(:app) { build(:app, :state => "STOPPED") }

            it "does not invoke the restart command" do
              push.stub(:line)
              app.should_receive(:update!)
              push.should_not_receive(:invoke).with(:restart, :app => app)
              subject
            end
          end
        end

        context "when buildpack is given" do
          let(:old) { nil }
          let(:app) { build(:app, :buildpack => old) }
          let(:inputs) { {:buildpack => new} }

          context "and it's an invalid URL" do
            let(:new) { "git@github.com:foo/bar.git" }

            before do
              app.stub(:update!) do
                raise CFoundry::MessageParseError.new(
                  "Request invalid due to parse error: Field: buildpack, Error: Value git@github.com:cloudfoundry/heroku-buildpack-ruby.git doesn't match regexp String /GIT_URL_REGEX/",
                  1001)
              end
            end

            it "fails and prints a pretty message" do
              push.stub(:line)
              expect { subject }.to raise_error(
                CF::UserError, "Buildpack must be a public git repository URI.")
            end
          end

          context "and it's a valid URL" do
            let(:new) { "git://github.com/foo/bar.git" }

            it "updates the app's buildpack" do
              push.stub(:line)
              app.should_receive(:update!)
              expect { subject }.to change { app.buildpack }.from(old).to(new)
            end

            it "outputs the changed buildpack with single quotes" do
              push.should_receive(:line).with("Changes:")
              push.should_receive(:line).with("buildpack: '' -> '#{new}'")
              app.stub(:update!)
              subject
            end

            include_examples "common tests for inputs", :buildpack
          end
        end
      end

      describe "#setup_new_app (integration spec!!)" do
        let(:app) { build(:app) }
        let(:host) { "" }
        let(:domain) { build(:domain) }
        let(:inputs) do
          { :name => "some-app",
            :instances => 2,
            :memory => 1024,
            :host => host,
            :domain => domain
          }
        end
        let(:global) { {:quiet => true, :color => false, :force => true} }

        before do
          client.stub(:app) { app }
        end

        subject do
          push.input = Mothership::Inputs.new(Mothership.commands[:push], push, inputs, global, global)
          push.setup_new_app(path)
        end

        it "creates the app" do
          app.should_receive(:create!)
          app.should_receive(:upload).with(path)
          push.should_receive(:filter).with(:create_app, app) { app }
          push.should_receive(:filter).with(:push_app, app) { app }
          push.should_receive(:invoke).with(:map, :app => app, :host => host, :domain => domain)
          push.should_receive(:invoke).with(:start, :app => app)
          subject
        end
      end
    end
  end
end
