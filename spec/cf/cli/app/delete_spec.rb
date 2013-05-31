require 'spec_helper'
require "cf/cli/app/delete"

describe CF::App::Delete do
  let(:global) { { :color => false, :quiet => true } }
  let(:inputs) { {} }
  let(:given) { {} }
  let(:client) { fake_client }
  let(:app) {}
  let(:new_name) { "some-new-name" }

  before do
    CF::CLI.any_instance.stub(:client).and_return(client)
    CF::CLI.any_instance.stub(:precondition).and_return(nil)
  end

  subject { Mothership.new.invoke(:delete, inputs, given, global) }

  describe 'metadata' do
    let(:command) { Mothership.commands[:delete] }

    describe 'command' do
      subject { command }
      its(:description) { should eq "Delete an application" }
      it { expect(Mothership::Help.group(:apps, :manage)).to include(subject) }
    end

    include_examples 'inputs must have descriptions'

    describe 'arguments' do
      subject { command.arguments }
      it 'has the correct argument order' do
        should eq([{ :type => :splat, :value => nil, :name => :apps }])
      end
    end
  end

  context 'when there are no apps' do
    context 'and an app is given' do
      let(:given) { { :app => "some-app" } }
      it { expect { subject }.to raise_error(CF::UserError, "Unknown app 'some-app'.") }
    end

    context 'and an app is not given' do
      it { expect { subject }.to raise_error(CF::UserError, "No applications.") }
    end
  end

  context 'when there are apps' do
    let(:client) { fake_client(:apps => apps) }
    let(:apps) { [basic_app, app_with_orphans, app_without_orphans] }
    let(:service_1) { fake :service_instance }
    let(:service_2) { fake :service_instance }
    let(:basic_app) { fake(:app, :name => "basic_app") }
    let(:app_with_orphans) {
      fake :app,
        :name => "app_with_orphans",
        :service_bindings => [
          fake(:service_binding, :service_instance => service_1),
          fake(:service_binding, :service_instance => service_2)
        ]
    }
    let(:app_without_orphans) {
      fake :app,
        :name => "app_without_orphans",
        :service_bindings => [
          fake(:service_binding, :service_instance => service_1)
        ]
    }

    context 'and no app is given' do
      it 'asks for the app' do
        mock_ask("Delete which application?", anything) { basic_app }
        stub_ask { true }
        basic_app.stub(:delete!)
        subject
      end
    end

    context 'and a basic app is given' do
      let(:deleted_app) { basic_app }
      let(:given) { { :app => deleted_app.name } }

      context 'and it asks for confirmation' do
        context 'and the user answers no' do
          it 'does not delete the application' do
            mock_ask("Really delete #{deleted_app.name}?", anything) { false }
            deleted_app.should_not_receive(:delete!)
            subject
          end
        end

        context 'and the user answers yes' do
          it 'deletes the application' do
            mock_ask("Really delete #{deleted_app.name}?", anything) { true }
            deleted_app.should_receive(:delete!)
            subject
          end
        end
      end

      context 'and --force is given' do
        let(:global) { { :force => true, :color => false, :quiet => true } }

        it 'deletes the application without asking to confirm' do
          dont_allow_ask
          deleted_app.should_receive(:delete!)
          subject
        end
      end
    end

    context 'and an app with orphaned services is given' do
      let(:deleted_app) { app_with_orphans }
      let(:inputs) { { :app => deleted_app } }

      context 'and it asks for confirmation' do
        context 'and the user answers yes' do
          it 'asks to delete orphaned services' do
            stub_ask("Really delete #{deleted_app.name}?", anything) { true }
            deleted_app.stub(:delete!)

            service_2.stub(:invalidate!)

            mock_ask("Delete orphaned service #{service_2.name}?", anything) { true }

            CF::App::Delete.any_instance.should_receive(:invoke).with(:delete_service, :service => service_2, :really => true)

            subject
          end
        end

        context 'and the user answers no' do
          it 'does not ask to delete orphaned serivces, or delete them' do
            stub_ask("Really delete #{deleted_app.name}?", anything) { false }
            deleted_app.should_not_receive(:delete!)

            service_2.stub(:invalidate!)

            dont_allow_ask("Delete orphaned service #{service_2.name}?")

            CF::App::Delete.any_instance.should_not_receive(:invoke).with(:delete_service, anything)

            subject
          end
        end
      end

      context 'and --force is given' do
        let(:global) { { :force => true, :color => false, :quiet => true } }

        it 'does not delete orphaned services' do
          dont_allow_ask
          deleted_app.stub(:delete!)

          CF::App::Delete.any_instance.should_not_receive(:invoke).with(:delete_service, anything)

          subject
        end
      end

      context 'and --delete-orphaned is given' do
        let(:inputs) { { :app => deleted_app, :delete_orphaned => true } }

        it 'deletes the orphaned services' do
          stub_ask("Really delete #{deleted_app.name}?", anything) { true }
          deleted_app.stub(:delete!)

          CF::App::Delete.any_instance.should_receive(:invoke).with(:delete_service, :service => service_2, :really => true)

          subject
        end
      end
    end
  end
end
