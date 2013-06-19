require "spec_helper"

module CF
  module App
    describe Scale do
      before do
        stub_client_and_precondition
      end

      let(:client) { build(:client) }
      let(:app) { }

      before do
        client.stub(:apps).and_return([app])
      end

      context "when the --disk flag is given" do
        let(:before_value) { 512 }
        let(:app) { build(:app, :disk_quota => before_value) }

        subject { cf %W[scale #{app.name} --disk 1G] }

        it "changes the application's disk quota" do
          app.should_receive(:update!)
          expect { subject }.to change(app, :disk_quota).from(before_value).to(1024)
        end
      end

      context "when the --memory flag is given" do
        let(:before_value) { 512 }
        let(:app) { build(:app, :memory => before_value) }

        subject { cf %W[scale #{app.name} --memory 1G] }

        it "changes the application's memory" do
          app.should_receive(:update!)
          expect { subject }.to change(app, :memory).from(before_value).to(1024)
        end

        context "if --restart is true" do
          it "restarts the application" do
            app.stub(:update!)
            app.stub(:started?) { true }
            mock_invoke :restart, :app => app
            subject
          end
        end
      end

      context "when the --instances flag is given" do
        let(:before_value) { 3 }
        let(:app) { build(:app, :total_instances => before_value) }

        subject { cf %W[scale #{app.name} --instances 5] }

        it "changes the application's number of instances" do
          app.should_receive(:update!)
          expect { subject }.to change(app, :total_instances).from(before_value).to(5)
        end
      end

      context "with an app that failed staging" do
        let(:app) { build(:app) }

        before do
          app.stub(:update!) { raise CFoundry::StagingError.new("Failed to stage", 170001, nil, nil) }
        end

        subject { cf %W[scale #{app.name} --instances 5] }

        it "says the app failed to stage" do
          expect {subject}.to raise_error(CF::UserFriendlyErrorWithDetails)
        end
      end
    end
  end
end
