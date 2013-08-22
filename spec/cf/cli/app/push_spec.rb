require "spec_helper"

module CF
  module App
    describe Push do
      let(:global) { {:color => false, :quiet => true} }
      let(:inputs) { {} }
      let(:given) { {} }
      let(:path) { "/somepath" }
      let(:client) { build(:client) }
      let(:push) { CF::App::Push.new(Mothership.commands[:push]) }

      before do
        CF::CLI.any_instance.stub(:client) { client }
        CF::CLI.any_instance.stub(:precondition) { nil }
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:push] }

        describe "has the correct information" do
          subject { command }
          its(:description) { should eq "Push an application, syncing changes if it exists" }
          it { expect(Mothership::Help.group(:apps, :manage)).to include(subject) }
        end

        it_behaves_like "inputs must have descriptions"
      end

      describe "#push" do
        let(:app) { build(:app, :client => client, :name => "app-name-1") }

        before do
          app.stub(:upload)
          app.changes = {}
          push.stub(:warn)
          client.stub(:app_by_name).and_return(app)
        end

        let(:inputs) { {} }

        shared_examples_for "an input" do |*args|
          context "when the new input is the same as the old" do
            type, input = args
            input ||= type

            let(:inputs) { {input => old} }

            it "does not update the app's #{type}" do
              push.should_not_receive(:line)
              app.should_not_receive(:update!)
              expect do
                push.input = Mothership::Inputs.new(Mothership.commands[:push], push, inputs, {}, global)
                push.push
              end.not_to change { app.send(type) }
            end
          end
        end

        it "triggers the :push_app filter" do
          push.should_receive(:filter).with(:push_app, app) { app }
          push.input = Mothership::Inputs.new(Mothership.commands[:push], push, inputs, {}, global)
          push.push
        end

        describe 'uploading the app from the correct path' do
          context 'when the user does not specify a path' do
            it 'uploads the app' do
              app.should_receive(:upload).with(File.expand_path('.'))
              push.input = Mothership::Inputs.new(Mothership.commands[:push], push, {}, {}, global)
              push.push
            end
          end

          context 'when the user specifies a path' do
            it 'uploads the app' do
              app.should_receive(:upload).with(path)
              push.input = Mothership::Inputs.new(Mothership.commands[:push], push, {:path => path}, {}, global)
              push.push
            end
          end
        end

        context "when the app is stopped" do
          before do
            app.stub(:started?).and_return(false)
          end

          it "warns the user" do
            push.should_receive(:warn).with("\n#{app.name} is currently stopped, start it with 'cf start'")
            push.input = Mothership::Inputs.new(nil, push, {:path => path}, {}, global)
            push.push
          end
        end

        context "when no inputs other than path are given" do
          let(:inputs) { {:path => ""} }

          it "should not update the app" do
            app.should_not_receive(:update!)
            push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
            push.push
          end

          it "should not set memory on the app" do
            app.should_not_receive(:memory=)
            push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
            push.push
          end
        end

        context "when memory is given" do
          let(:old) { 1024 }
          let(:new) { "2G" }
          let(:app) { build(:app, :memory => old) }
          let(:inputs) { {:path => path, :memory => new} }

          it "updates the app memory, converting to megabytes" do
            push.stub(:line)
            app.should_receive(:update!)
            expect { push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
            push.push }.to change { app.memory }.from(old).to(2048)
          end

          it "outputs the changed memory in human readable sizes" do
            push.should_receive(:line).with("Changes:")
            push.should_receive(:line).with("memory: 1G -> 2G")
            app.stub(:update!)
            push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
            push.push
          end

          it_behaves_like "an input", :memory
        end

        context "when instances is given" do
          let(:old) { 1 }
          let(:new) { 2 }
          let(:app) { build(:app, :total_instances => old) }
          let(:inputs) { {:path => path, :instances => new} }

          it "updates the app instances" do
            push.stub(:line)
            app.stub(:update!)
            expect do
              push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
              push.push
            end.to change { app.total_instances }.from(old).to(new)
          end

          it "outputs the changed instances" do
            push.should_receive(:line).with("Changes:")
            push.should_receive(:line).with("total_instances: 1 -> 2")
            app.stub(:update!)
            push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
            push.push
          end

          it_behaves_like "an input", :total_instances, :instances
        end

        context "when command is given" do
          let(:old) { "./start" }
          let(:new) { "./start foo " }
          let(:app) { build(:app, :command => old) }
          let(:inputs) { {:path => path, :command => new} }

          it "updates the app command" do
            push.stub(:line)
            app.should_receive(:update!)
            expect do
              push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
              push.push
            end.to change { app.command }.from("./start").to("./start foo ")
          end

          it "outputs the changed command in single quotes" do
            push.should_receive(:line).with("Changes:")
            push.should_receive(:line).with("command: './start' -> './start foo '")
            app.stub(:update!)
            push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
            push.push
          end

          it_behaves_like "an input", :command
        end

        context "when restart is given" do
          let(:inputs) { {:path => path, :restart => true, :memory => 4096} }

          let(:mock_restart_command) do
            MockRestartCommand.new
          end

          before do
            CF::App::Base.any_instance.stub(:human_mb).and_return(0)
            Restart.stub(:new).and_return(mock_restart_command)
          end

          context "when the app is already started" do
            let(:app) { build(:app, :state => "STARTED") }

            it "restarts the app after updating" do
              push.stub(:line)
              app.should_receive(:update!) do
                expect(mock_restart_command.restarted_apps).to be_empty
              end

              push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
              push.push

              expect(mock_restart_command.restarted_apps).to eq [app]
            end

            context "but there are no changes" do
              let(:inputs) { {:path => path, :restart => true} }

              it "restarts the app without updating" do
                push.stub(:line)
                app.should_not_receive(:update!)

                push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
                push.push

                mock_restart_command.restarted_apps.should == [app]
              end
            end
          end

          context "when the app is not already started" do
            let(:app) { build(:app, :state => "STOPPED") }

            it "updates the app without restarting" do
              push.stub(:line)
              app.should_receive(:update!)

              push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
              push.push

              expect(mock_restart_command.restarted_apps).to be_empty
            end
          end
        end

        context "when buildpack is given" do
          let(:old) { nil }
          let(:app) { build(:app, :buildpack => old) }
          let(:inputs) { {:path => path, :buildpack => new} }

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
              expect do
                push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
                push.push
              end.to raise_error(
                                 CF::UserError, "Buildpack must be a public git repository URI.")
            end
          end

          context "and it's a valid URL" do
            let(:new) { "git://github.com/foo/bar.git" }

            it "updates the app's buildpack" do
              push.stub(:line)
              app.should_receive(:update!)
              expect do
                push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
                push.push
              end.to change { app.buildpack }.from(old).to(new)
            end

            it "outputs the changed buildpack with single quotes" do
              push.should_receive(:line).with("Changes:")
              push.should_receive(:line).with("buildpack: '' -> '#{new}'")
              app.stub(:update!)
              push.input = Mothership::Inputs.new(nil, push, inputs, {}, global)
              push.push
            end

            it_behaves_like "an input", :buildpack
          end
        end
      end

      describe "#setup_new_app (integration spec!!)" do
        let(:app) { build(:app) }
        let(:host) { "" }
        let(:domain) { build(:domain) }
        let(:inputs) do
          {:name => "some-app",
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
