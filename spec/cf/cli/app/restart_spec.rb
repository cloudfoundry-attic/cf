require "spec_helper"

module CF
  module App
    describe Restart do
      let(:restart_command) { CF::App::Restart.new(Mothership.commands[:restart]) }
      let(:inputs) { {:apps => [app]} }
      let(:app) { build(:app, :command => "rails s") }

      before do
        restart_command.input = Mothership::Inputs.new(nil, restart_command, inputs, {}, {})
        app.stub(:update!)
      end

      it "restarts the application" do
        restart_command.should_receive(:invoke).with(:stop, anything) do
          restart_command.should_receive(:invoke).with(:start, anything)
        end
        restart_command.restart
      end

      it "does not change the command if we do not pass the command argument" do
        restart_command.stub(:invoke).with(:start, anything)
        restart_command.stub(:invoke).with(:stop, anything)
        restart_command.restart
        app.command.should == "rails s"
      end

      context "when passing in a new start command" do
        let(:inputs) { {:apps => [app], :command => 'rake db:migrate'} }

        before do
          restart_command.stub(:invoke).with(:stop, anything)
          restart_command.input = Mothership::Inputs.new(nil, restart_command, inputs, {}, {})
        end

        it "updates the start command" do
          app.should_receive(:update!) do
            restart_command.should_receive(:invoke).with(:start, anything)
          end
          restart_command.restart
          app.command.should == "rake db:migrate"
        end
      end
    end
  end
end
