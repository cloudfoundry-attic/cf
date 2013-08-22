require "spec_helper"
require "cf/cli/app/env"

module CF
  module App
    describe Env do
      before do
        stub_client
      end

      describe '#set_env' do
        let(:mock_restart_command) { MockRestartCommand.new }
        let(:mock_start_command) { MockStartCommand.new }
        let(:client) { build(:client) }
        let(:app) { build(:app, client: client, name: 'puppies-r-us-website') }
        let(:env) { Env.new(Mothership.commands[:set_env]) }

        before do
          client.stub(:app_by_name).and_return(app)
          env.input = Mothership::Inputs.new(Mothership.commands[:set_env], env, inputs, {}, {})
        end

        context 'when name and value are specified' do
          let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', value: 'oh_what_a_value'} }

          it 'updates the app with the new environment variable' do
            expect(app.env['MY_LOVELY_SETTING']).to eq(nil)
            expect(app).to receive(:update!) do
              expect(app.env['MY_LOVELY_SETTING']).to eq('oh_what_a_value')
            end

            capture_output { env.set_env }
          end
        end

        context "when the environment variable is specified with the 'VAR=VALUE' format" do
          let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING=oh_what_a_value'} }

          it 'updates the app with the new environment variable' do
            expect(app.env['MY_LOVELY_SETTING']).to eq(nil)
            expect(app).to receive(:update!) do
              expect(app.env['MY_LOVELY_SETTING']).to eq('oh_what_a_value')
            end

            capture_output { env.set_env }
          end
        end

        describe "environment variable format" do
          context "when the name has only letters, numbers, and underscores" do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING123', value: "oh_what_a_value"} }
            it "gets the value from the input[:value]" do
              expect(app.env['MY_LOVELY_SETTING123']).to eq(nil)
              app.stub(:update!)

              capture_output { env.set_env }
              expect(app.env['MY_LOVELY_SETTING123']).to eq("oh_what_a_value")
            end
          end

          context "when the name has one equal sign, and is otherwise valid" do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING123=oh_what_a_value'} }
            it "gets the value by parsing the name" do
              expect(app.env['MY_LOVELY_SETTING123']).to eq(nil)
              app.stub(:update!)

              capture_output { env.set_env }
              expect(app.env['MY_LOVELY_SETTING123']).to eq("oh_what_a_value")
            end

            context "but provides a value anyway" do
              let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING123=oh_what_a_value', value: 'my_other_value'} }

              it "gives the user an error" do
                capture_exceptional_output { env.set_env }
                expect(error_output).to say "You attempted to specify the value of MY_LOVELY_SETTING123 twice."
              end
            end
          end

          context "when the name has more than one equal sign" do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING123=oh_what_a_value=badbadbad'} }
            it "gives the user an error" do
              capture_exceptional_output { env.set_env }
              expect(error_output).to say "Invalid format: environment variable definition contains too many occurences of '='"
            end
          end

          context "when there are characters that are not letters, numbers, or underscores" do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING1?#$=value'} }
            it "raises an error" do
              capture_exceptional_output { env.set_env }
              expect(error_output).to say "Invalid format: environment variable names can only contain alphanumeric characters and underscores"
            end
          end

          context "when the name starts with a number" do
            let(:inputs) { {app: app, name: '1MY_LOVELY_SETTING', value: 'oh_what_a_value'} }
            it "raises an error" do
              capture_exceptional_output { env.set_env }
              expect(error_output).to say "Invalid format: environment variable names cannot start with a number"
            end
          end
        end

        context 'when the app is not started' do
          context 'with the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', value: 'oh_what_a_value', restart: true} }
            before { Start.stub(:new).and_return(mock_start_command) }

            it 'starts the app' do
              expect(app).to receive(:update!) do
                expect(mock_start_command.started_apps).to be_empty
              end

              capture_output { env.set_env }
              expect(output).to say "Your app was unstarted. Starting now."

              expect(mock_start_command.started_apps).to eq [app]
            end
          end

          context 'without the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', value: 'oh_what_a_value', restart: false} }

            before do
              app.stub(:update!)
            end

            it "suggests a 'cf push' to the user" do
              capture_output { env.set_env }
              expect(output).to say "TIP: Use 'cf push' to ensure your env variable changes take effect."
            end
          end
        end

        context 'when the app is already started' do
          before do
            app.stub(:started?) { true }
            Restart.stub(:new).and_return(mock_restart_command)
          end

          context 'with the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', value: 'oh_what_a_value', restart: true} }

            it 'restarts the app' do
              expect(app).to receive(:update!) do
                expect(mock_restart_command.restarted_apps).to be_empty
              end

              capture_output { env.set_env }

              expect(mock_restart_command.restarted_apps).to eq([app])
            end
          end

          context 'without the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', value: 'oh_what_a_value', restart: false} }
            before do
              app.stub(:update!)
            end

            it 'does not restart the app but suggests a cf push' do
              capture_output { env.set_env }
              expect(mock_restart_command.restarted_apps).to be_empty
              expect(output).to say "TIP: Use 'cf push' to ensure your env variable changes take effect."
            end
          end
        end
      end

      describe '#unset_env' do
        let(:app) { build(:app, client: client, name: 'puppies-r-us-website', environment_json: {'MY_LOVELY_SETTING' => 'oh_so_lovely'}) }
        let(:client) { build(:client) }
        let(:env) { Env.new(Mothership.commands[:unset_env]) }
        let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING'} }
        let(:mock_start_command) { MockStartCommand.new }
        let(:mock_restart_command) { MockRestartCommand.new }

        before do
          env.input = Mothership::Inputs.new(Mothership.commands[:unset_env], env, inputs, {}, {})
        end

        it 'unsets the environment variable and updates the app' do
          expect(app.env['MY_LOVELY_SETTING']).to eq('oh_so_lovely')
          expect(app).to receive(:update!) do
            expect(app.env['MY_LOVELY_SETTING']).to be_nil
          end

          capture_output { env.unset_env }
        end

        context 'when the app is not started' do
          context 'with the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', restart: true} }
            before { Start.stub(:new).and_return(mock_start_command) }

            it 'starts the app' do
              expect(app).to receive(:update!) do
                expect(mock_start_command.started_apps).to be_empty
              end

              capture_output { env.unset_env }
              expect(output).to say "Your app was unstarted. Starting now."

              expect(mock_start_command.started_apps).to eq [app]
            end
          end

          context 'without the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING'} }

            before do
              app.stub(:update!)
            end

            it "suggests a 'cf push' to the user" do
              capture_output { env.unset_env }
              expect(output).to say "TIP: Use 'cf push' to ensure your env variable changes take effect."
            end
          end
        end

        context 'when the app is already started' do
          before do
            app.stub(:started?) { true }
            Restart.stub(:new).and_return(mock_restart_command)
          end

          context 'with the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', restart: true} }

            it 'restarts the app' do
              expect(app).to receive(:update!) do
                expect(mock_restart_command.restarted_apps).to be_empty
              end

              capture_output { env.unset_env }

              expect(mock_restart_command.restarted_apps).to eq([app])
            end
          end

          context 'without the --restart flag' do
            let(:inputs) { {app: app, name: 'MY_LOVELY_SETTING', restart: false} }
            before do
              app.stub(:update!)
            end

            it 'does not restart the app but suggests a cf push' do
              capture_output { env.unset_env }
              expect(mock_restart_command.restarted_apps).to be_empty
              expect(output).to say "TIP: Use 'cf push' to ensure your env variable changes take effect."
            end
          end
        end
      end
    end
  end
end

