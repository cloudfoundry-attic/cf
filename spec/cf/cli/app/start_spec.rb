require "spec_helper"

module CF
  module App
    describe Start do
      let(:client) { build(:client) }
      let(:app) { build(:app, :client => client, :name => "app-name", :guid => "app-id-1") }

      before do
        stub_client_and_precondition
        client.stub(:apps).and_return([app])

        app.stub(:host).and_return("some_host")
        app.stub(:domain).and_return("some_domain")
        app.stub(:subdomain).and_return("some_subdomain")
      end

      def execute_start_app
        cf %W[start #{app.name}]
      end

      context "with an app that's already started" do
        let(:app) { build(:app, :state => "STARTED") }

        it "skips starting the application" do
          app.should_not_receive(:start!)
          execute_start_app
        end

        it "says the app is already started" do
          execute_start_app
          expect(error_output).to say("Application #{app.name} is already started.")
        end
      end

      context "with an app that's NOT already started" do
        def self.it_says_application_is_starting
          it "says that it's starting the application" do
            execute_start_app
            expect(output).to say("Preparing to start #{app.name}... OK")
          end
        end

        def self.it_prints_log_progress
          it "prints out the log progress" do
            execute_start_app
            expect(output).to say(log_text)
          end
        end

        def self.it_does_not_print_log_progress
          it "does not print the log progress" do
            execute_start_app
            expect(output).to_not say(log_text)
          end
        end

        def self.it_waits_for_application_to_become_healthy
          describe "waits for application to become healthy" do
            let(:app) { build(:app, :total_instances => 2) }

            def after_sleep
              described_class.any_instance.stub(:sleep) { yield }
            end

            before do
              app.stub(:instances) do
                [CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "DOWN"),
                  CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "DOWN")
                ]
              end

              after_sleep do
                app.stub(:instances) { final_instances }
              end
            end

            context "when one instance becomes running" do
              let(:final_instances) do
                [CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "RUNNING"),
                  CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "DOWN")
                ]
              end

              it "says app is started" do
                execute_start_app
                expect(output).to say("Checking status of app '#{app.name}'...")
                expect(output).to say("1 running, 1 down")
                expect(output).to say("Push successful!")
              end
            end

            context "staging fails" do
              before do
                app.stub(:instances) { raise CFoundry::StagingError.new("Failed to stage", 170001, nil, nil) }
              end

              it "says the app failed to stage" do
                execute_start_app
                expect(output).to say("Checking status of app '#{app.name}'...")
                expect(error_output).to say("Application failed to stage")
                expect(output).to_not say(/\d (running|down|flapping)/)
              end
            end

            context "staging has not completed" do
              let(:final_instances) do
                [CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "RUNNING"),
                  CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "RUNNING")
                ]
              end

              before do
                app.stub(:instances) { raise CFoundry::NotStaged.new("Staging is pending", 170002, nil, nil) }
              end

              it "keeps polling" do
                execute_start_app
                expect(output).to say("Checking status of app '#{app.name}'...")
                expect(output).to say("2 running")
              end
            end

            context "when any instance becomes flapping" do
              before do
                app.stub(:instances) do
                  [
                    CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "FLAPPING"),
                    CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "DOWN"),
                  ]
                end
              end

              it "says app failed to start" do
                execute_start_app
                expect(output).to say("Checking status of app '#{app.name}'...")
                expect(output).to say("1 crashing, 1 down")
                expect(error_output).to say("Push unsuccessful.")
              end
            end
          end
        end

        let(:log_url) { nil }

        before do
          app.stub(:invalidate!)
          app.stub(:instances) do
            [CFoundry::V2::AppInstance.new(nil, nil, nil, nil, :state => "RUNNING")]
          end

          app.should_receive(:start!) do |_, &blk|
            app.state = "STARTED"
            blk.call(log_url)
          end
        end

        context "when progress log url is provided" do
          let(:log_url) { "http://example.com/my-app-log" }
          let(:log_text) { "Staging complete!" }

          context "and progress log url is not available immediately" do
            before do
              stub_request(:get, "#{log_url}&tail&tail_offset=0").to_return(
                :status => 404, :body => "")
            end

            it_says_application_is_starting
            it_does_not_print_log_progress
            it_waits_for_application_to_become_healthy
          end

          context "and progress log url becomes unavailable after some time" do
            before do
              stub_request(:get, "#{log_url}&tail&tail_offset=0").to_return(
                :status => 200, :body => log_text[0...5])
              stub_request(:get, "#{log_url}&tail&tail_offset=5").to_return(
                :status => 200, :body => log_text[5..-1])
              stub_request(:get, "#{log_url}&tail&tail_offset=#{log_text.size}").to_return(
                :status => 404, :body => "")
            end

            it_says_application_is_starting
            it_prints_log_progress
            it_waits_for_application_to_become_healthy
          end

          context "and a request times out" do
            before do
              stub_request(:get, "#{log_url}&tail&tail_offset=0").to_return(
                :should_timeout => true)
              stub_request(:get, "#{log_url}&tail&tail_offset=0").to_return(
                :status => 200, :body => log_text)
              stub_request(:get, "#{log_url}&tail&tail_offset=#{log_text.size}").to_return(
                :status => 404, :body => "")
            end

            it_says_application_is_starting
            it_prints_log_progress
            it_waits_for_application_to_become_healthy
          end
        end

        context "when progress log url is not provided" do
          let(:log_url) { nil }
          let(:log_text) { "Staging complete!" }

          it_says_application_is_starting
          it_does_not_print_log_progress
          it_waits_for_application_to_become_healthy
        end

        context "when a debug mode is given" do
          let(:mode) { "some_mode" }

          def execute_start_app_with_mode
            cf %W[start #{app.name} -d #{mode}]
          end

          context "and the debug mode is different from the one already set" do
            it "starts the app with the given debug mode" do
              expect { execute_start_app_with_mode }.to change { app.debug }.from(nil).to("some_mode")
            end
          end

          context "and the debug mode is the same as the one already set" do
            let(:app) { build(:app, :debug => "in_debug") }

            it "does not set the debug mode to anything different" do
              app.should_not_receive(:debug).with(anything)
              execute_start_app_with_mode
            end
          end

          context "and the mode is given as 'none'" do
            let(:app) { build(:app, :debug => "in_debug") }
            let(:mode) { "none" }

            it "removes the debug mode" do
              expect { execute_start_app_with_mode }.to change { app.debug }.from("in_debug").to("none")
            end
          end

          context "and an empty mode is given" do
            let(:mode) { "" }

            it "sets debug to 'run'" do
              expect { execute_start_app_with_mode }.to change { app.debug }.from(nil).to("run")
            end
          end
        end
      end
    end
  end
end
