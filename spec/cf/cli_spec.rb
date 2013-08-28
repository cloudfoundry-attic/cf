require "spec_helper"

module CF
  describe CLI do
    let(:context) { CF::CLI.new }
    let(:command) { nil }

    let(:fake_home_dir) { nil }
    stub_home_dir_with { fake_home_dir }

    describe "#wrap_errors" do
      let(:inputs) { {} }

      subject do
        capture_output do
          context.stub(:input) { inputs }
          context.wrap_errors { action.call }
        end
      end

      context "with a CFoundry::Timeout" do
        let(:action) { proc { raise CFoundry::Timeout.new(123, "fizzbuzz") } }

        it_behaves_like "an error that's obvious to the user", :with_message => "fizzbuzz"
      end

      context "with a UserError" do
        let(:action) { proc { context.fail "foo bar" } }

        it_behaves_like "an error that's obvious to the user",
          :with_message => "foo bar"

        it "saves it in the crashlog" do
          context.should_receive(:log_error)
          subject
        end
      end

      context "with a UserFriendlyError" do
        let(:action) { proc { raise CF::UserFriendlyError.new("user friendly") } }

        it_behaves_like "an error that's obvious to the user",
          :with_message => "user friendly"
      end

      context "with a CFoundry::StagingError" do
        let(:exception) { CFoundry::StagingError.new("whatever", 170001, nil, nil) }
        let(:action) { proc { raise exception } }
        before { exception.should_receive(:backtrace).at_least(1).times.and_return([]) }

        it "prints the message" do
          subject
          expect(stderr.string).to include "Application failed to stage"
        end

        it "sets the exit code to 1" do
          context.should_receive(:exit_status).with(1)
          subject
        end

        it "logs the error" do
          context.should_receive(:log_error).with(anything)
          subject
        end
      end

      context "with a SystemExit" do
        let(:action) { proc { exit 1 } }

        it_behaves_like "an error that gets passed through",
          :with_exception => SystemExit
      end

      context "with a Mothership::Error" do
        let(:action) { proc { raise Mothership::Error } }

        it_behaves_like "an error that gets passed through",
          :with_exception => Mothership::Error
      end

      context "with an Interrupt" do
        let(:action) { proc { raise Interrupt } }

        it "sets the exit code to 130" do
          context.should_receive(:exit_status).with(130)
          subject
        end
      end

      context "when CC can't decode the auth token" do
        let(:action) { proc { raise CFoundry::InvalidAuthToken.new("foo bar") } }
        let(:asked) { false }

        before do
          $cf_asked_auth = asked
        end

        it "tells the user they are not authenticated" do
          subject
          expect(stdout.string).to include "Invalid authentication token. Try logging in again with 'cf login'. If problems continue, please contact your Cloud Operator."
        end

        it "exits without attempting to login again" do
          context.should_not_receive(:invoke)
          subject
        end
      end

      context "with a CFoundry authentication error" do
        let(:action) { proc { raise CFoundry::Forbidden.new("foo bar") } }
        let(:asked) { false }

        before do
          $cf_asked_auth = asked
        end

        it "tells the user they are not authenticated" do
          context.stub(:invoke)
          subject
          expect(stdout.string).to include "Not authenticated! Try logging in:"
          expect($cf_asked_auth).to be_true
        end

        it "asks the user to log in" do
          context.should_receive(:invoke).with(:login)
          subject
        end

        context "and after logging in they got another authentication error" do
          let(:asked) { true }

          it "does not ask them to log in" do
            context.should_not_receive(:invoke)
            subject
          end

          it_behaves_like "an error that's obvious to the user",
            :with_message => "Denied: foo bar"
        end
      end

      context "with a CFoundry API error" do
        let(:error) { CFoundry::APIError.new("CC had a problem", 123) }
        let(:action) { proc { raise error } }

        it "prints the error message" do
          subject
          expect(stderr.string).to include "APIError: 123: CC had a problem"
        end

        it "does not include the crash log" do
          subject
          expect(stderr.string).to_not include "spec/cf/cli_spec.rb"
        end
      end

      context "with an arbitrary exception" do
        let(:error) { RuntimeError.new("ahhhh it's all broken!!!!") }
        let(:action) { proc { raise error } }

        it "prints the error message" do
          subject
          expect(stderr.string).to include "RuntimeError: ahhhh it's all broken!!!!"
        end

        it "prints the crash log" do
          subject
          expect(stderr.string).to include "spec/cf/cli_spec.rb"
        end

        it "sets the exit code to 1" do
          context.should_receive(:exit_status).with(1)
          subject
        end

        context "when we are debugging" do
          let(:inputs) { {:debug => true} }

          it_behaves_like "an error that gets passed through",
            :with_exception => RuntimeError
        end
      end
    end

    describe "#execute" do
      let(:inputs) { {} }
      let(:client) { build(:client) }

      before do
        stub_client
      end

      subject do
        capture_output do
          context.stub(:input) { inputs }
          context.execute(command, [])
        end
      end

      describe "token refreshing" do
        let(:context) { TokenRefreshDummy.new }
        let(:command) { Mothership.commands[:refresh_token] }
        let(:auth_token) { CFoundry::AuthToken.new("old-header") }
        let(:new_auth_token) { CFoundry::AuthToken.new("new-header") }

        class TokenRefreshDummy < CF::CLI
          class << self
            attr_accessor :new_token
          end

          def precondition;
          end

          def refresh_token
            if client
              client.token = self.class.new_token
            end
          end
        end

        context "when there is a target" do
          before do
            TokenRefreshDummy.new_token = nil
            client.token = auth_token
          end

          context "when the token refreshes" do
            it "saves to the target file" do
              TokenRefreshDummy.any_instance.stub(:target_info) { {} }
              TokenRefreshDummy.any_instance.stub(:save_target_info).with(anything) do |info|
                expect(info[:token]).to eq new_auth_token.auth_header
              end

              subject
            end
          end

          context "but there is no token initially" do
            let(:auth_token) { nil }

            it "doesn't save the new token because something else probably did" do
              context.should_not_receive(:save_target_info)
              subject
            end
          end

          context "and the token becomes nil" do
            let(:new_auth_token) { nil }

            it "doesn't save the nil token" do
              context.should_not_receive(:save_target_info)
              subject
            end
          end
        end

        context "when there is no target" do
          let(:client) { nil }

          it "doesn't try to compare the tokens" do
            expect { subject }.to_not raise_error
          end
        end
      end
    end

    describe "#log_error" do
      subject do
        context.log_error(exception)
        File.read(File.expand_path(CF::CRASH_FILE))
      end

      context "when the exception is a normal error" do
        let(:exception) do
          error = StandardError.new("gemfiles are kinda hard")
          error.set_backtrace(["fo/gems/bar", "baz quick"])
          error
        end

        it { should include "Time of crash:" }
        it { should include "gemfiles are kinda hard" }
        it { should include "bar" }
        it { should_not include "fo/gems/bar" }
        it { should include "baz quick" }
      end

      context "when the exception is an APIError" do
        let(:request) { {:method => "GET", :url => "http://api.cloudfoundry.com/foo", :headers => {}, :body => nil} }
        let(:response) { {:status => 404, :body => "bar", :headers => {}} }
        let(:exception) do
          error = CFoundry::APIError.new(nil, nil, request, response)
          error.set_backtrace(["fo/gems/bar", "baz quick"])
          error
        end

        before do
          response.stub(:body) { "Response Body" }
        end

        it { should include "REQUEST: " }
        it { should include "RESPONSE: " }
      end
    end

    describe "#client_target" do
      subject { context.client_target }

      context "when a ~/.cf/target exists" do
        let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

        it "returns the target in that file" do
          expect(subject).to eq "https://api.some-domain.com"
        end
      end

      context "when no target file exists" do
        let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/no_config" }

        it "returns nil" do
          expect(subject).to eq nil
        end
      end
    end

    describe "#targets_info" do
      subject { context.targets_info }

      context "when a ~/.cf/tokens.yml exists" do
        let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

        it "returns the file's contents as a hash" do
          expect(subject).to eq({
            "https://api.some-domain.com" => {
              :token => "bearer some-token",
              :version => 2
            }
          })
        end
      end

      context "when no token file exists" do
        let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/no_config" }

        it "returns an empty hash" do
          expect(subject).to eq({})
        end
      end
    end

    describe "#target_info" do
      subject { CF::CLI.new.target_info("https://api.some-domain.com") }

      context "when a ~/.cf/tokens.yml exists" do
        let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

        it "returns the info for the given url" do
          expect(subject).to eq({
            :token => "bearer some-token",
            :version => 2
          })
        end
      end

      context "when no token file exists" do
        let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/no_config" }

        it "returns an empty hash" do
          expect(subject).to eq({})
        end
      end
    end

    describe "methods that update the token info" do
      before do
        context.stub(:targets_info) do
          {
            "https://api.some-domain.com" => {:token => "bearer token1"},
            "https://api.some-other-domain.com" => {:token => "bearer token2"}
          }
        end
      end

      describe "#save_target_info" do
        it "adds the given target info, and writes the result to ~/.cf/tokens.yml" do
          context.save_target_info({:token => "bearer token3"}, "https://api.some-domain.com")
          YAML.load_file(File.expand_path("~/.cf/tokens.yml")).should == {
            "https://api.some-domain.com" => {:token => "bearer token3"},
            "https://api.some-other-domain.com" => {:token => "bearer token2"}
          }
        end
      end

      describe "#remove_target_info" do
        it "removes the given target, and writes the result to ~/.cf/tokens.yml" do
          context.remove_target_info("https://api.some-domain.com")
          YAML.load_file(File.expand_path("~/.cf/tokens.yml")).should == {
            "https://api.some-other-domain.com" => {:token => "bearer token2"}
          }
        end
      end
    end

    describe "#client" do
      let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_home_dirs/new" }

      before { context.stub(:input).and_return({}) }

      describe "the client's token" do
        it "constructs an AuthToken object with the data from the tokens.yml file" do
          expect(context.client.token).to be_a(CFoundry::AuthToken)
          expect(context.client.token.auth_header).to eq("bearer some-token")
        end

        it "does not assign an AuthToken on the client if there is no token stored" do
          context.should_receive(:target_info).with("some-fake-target") { {:version => 2} }
          expect(context.client("some-fake-target").token).to be_nil
        end
      end

      describe "the client's version" do
        it "uses the version stored in the yml file" do
          expect(context.client.version).to eq(2)
        end
      end

      context "with a cloud controller" do
        before do
          context.stub(:target_info) { {:version => 2} }
        end

        it "connects using the v2 api" do
          expect(context.client).to be_a(CFoundry::V2::Client)
        end

        %w{https_proxy HTTPS_PROXY http_proxy HTTP_PROXY}.each do |variable|
          proxy_name = variable.downcase.to_sym

          context "when ENV['#{variable}'] is set" do
            before { ENV[variable] = "http://lower.example.com:80" }
            after { ENV.delete(variable) }

            it "uses the #{proxy_name} proxy URI on the environment variable" do
              expect(context.client.send(proxy_name)).to eq("http://lower.example.com:80")
            end
          end
        end

        context "when both input and environment variable are provided" do
          before do
            ENV["HTTPS_PROXY"] = "http://should.be.overwritten.example.com:80"
            context.stub(:input) { {:https_proxy => "http://arg.example.com:80"} }
          end

          after { ENV.delete("HTTPS_PROXY") }

          it "uses the provided https proxy URI" do
            expect(context.client.https_proxy).to eq("http://arg.example.com:80")
          end
        end
      end
    end

    describe "#sane_target_url" do
      it "removes any trailing slashes" do
        expect(context.sane_target_url("http://example.com/")).to eq "http://example.com"
        expect(context.sane_target_url("https://example.com/")).to eq "https://example.com"
      end

      it "defaults to https when the given url has no http(s) scheme" do
        expect(context.sane_target_url("example.com")).to eq "https://example.com"
      end
    end
  end
end
