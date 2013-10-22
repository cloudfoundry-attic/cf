require "spec_helper"
require "webmock/rspec"

if ENV["CF_V2_RUN_INTEGRATION"]
  describe "A user pushing a new sinatra app", :ruby19 => true do
    let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
    let(:app) { "hello-sinatra-#{run_id}" }
    let(:subdomain) { "hello-sinatra-subdomain-#{run_id}" }
    let(:service_name) { "dummy-service-#{run_id}" }
    let(:user_provided_name) { "user-provided-#{run_id}"}

    before do
      FileUtils.rm_rf File.expand_path(CF::CONFIG_DIR)
      WebMock.allow_net_connect!
      Interact::Progress::Dots.start!
      login
    end

    after do
      `#{cf_bin} unbind-service -f --no-script #{service_name} #{app}`
      `#{cf_bin} delete-service -f --no-script #{service_name}`

      `#{cf_bin} unbind-service -f --no-script #{user_provided_name} #{app}`
      `#{cf_bin} delete-service -f --no-script #{user_provided_name}`

      `#{cf_bin} delete #{app} -f --routes --no-script`
      logout
      Interact::Progress::Dots.stop!
    end

    it "excercises the app workflow" do
      BlueShell::Runner.run("#{cf_bin} app #{app}") do |runner|
        expect(runner).to say "Unknown app '#{app}'."
      end

      Dir.chdir("#{SPEC_ROOT}/assets/hello-sinatra") do
        FileUtils.rm("manifest.yml", force: true)
        BlueShell::Runner.run("#{cf_bin} push") do |runner|
          expect(runner).to say "Name>"
          runner.send_keys app

          expect(runner).to say "Instances> 1"
          runner.send_return

          expect(runner).to_not say "Custom startup command> "

          runner.send_up_arrow
          expect(runner).to say "Instances> 1"
          runner.send_return

          expect(runner).to say "Memory Limit>"
          runner.send_keys "128M"

          expect(runner).to say "Creating #{app}... OK"

          expect(runner).to say "Subdomain> #{app}"

          runner.send_up_arrow
          expect(runner).not_to say "Memory Limit>"
          runner.send_keys subdomain

          expect(runner).to say "1:"
          expect(runner).to say "Domain>"
          runner.send_keys "1"

          expect(runner).to say(/Creating route #{subdomain}\..*\.\.\. OK/)
          expect(runner).to say(/Binding #{subdomain}\..* to #{app}\.\.\. OK/)

          expect(runner).to say "Create services for application?> n"
          runner.send_up_arrow
          expect(runner).not_to say "Domain>"
          runner.send_keys "y"

          # create a service here
          expect(runner).to say "What kind?>"
          runner.send_keys "dummy n/a"

          expect(runner).to say "Name?>"
          runner.send_keys service_name

          expect(runner).to say "Which plan?>"
          runner.send_keys "small"

          expect(runner).to say /Creating service #{service_name}.*OK/
          expect(runner).to say /Binding .+ to .+ OK/

          expect(runner).to say "Create another service?> n"
          runner.send_up_arrow
          expect(runner).not_to say "Which plan?>"
          runner.send_up_arrow
          expect(runner).not_to say "Which plan?>"
          runner.send_keys "y"

          # create a user-provided service here
          expect(runner).to say "What kind?>"
          runner.send_keys "user-provided"

          expect(runner).to say "Name?>"
          runner.send_keys user_provided_name

          expect(runner).not_to say "Which plan?>"
          expect(runner).to say "What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)>"
          runner.send_keys "uri"

          expect(runner).to say "uri>"
          runner.send_keys "mysql://u:p@example.com:3306/db"

          expect(runner).to say /Creating service #{user_provided_name}.*OK/
          expect(runner).to say /Binding .+ to .+ OK/

          expect(runner).to say "Create another service?> n"
          runner.send_keys "n"

          if runner.expect "Bind other services to application?> n", 15
            runner.send_return
          end

          expect(runner).to say "Save configuration?> n", 20
          runner.send_return

          expect(runner).to say "Uploading #{app}... OK", 180
          expect(runner).to say "Preparing to start #{app}... OK", 180
          expect(runner).to say "Checking status of app '#{app}'...", 180
          expect(runner).to say "1 of 1 instances running"
          expect(runner).to say "Push successful! App '#{app}' available at #{subdomain}.cfapps.io", 30
        end
      end

      BlueShell::Runner.run("#{cf_bin} services") do |runner|
        expect(runner).to say /name\s+service\s+provider\s+version\s+plan\s+bound apps/
        expect(runner).to say /dummy-service-.+?\s+ # name
            dummy\s+                        # service
            dummy\s+                              # provider
            n\/a\s+                             # version
            small\s+                             # plan
            #{app}                              # bound apps
          /x
      end

      BlueShell::Runner.run("#{cf_bin} unbind-service #{service_name} #{app}") do |runner|
        expect(runner).to say "OK", 20
      end

      BlueShell::Runner.run("#{cf_bin} set-env #{app} DEVELOP_ON_CLOUD_FOUNDRY all_day_erry_day") do |runner|
        expect(runner).to say "OK"
      end

      BlueShell::Runner.run("#{cf_bin} env #{app}") do |runner|
        expect(runner).to say "DEVELOP_ON_CLOUD_FOUNDRY: all_day_erry_day"
      end

      BlueShell::Runner.run("#{cf_bin} unset-env #{app} DEVELOP_ON_CLOUD_FOUNDRY") do |runner|
        expect(runner).to say "OK"
      end

      BlueShell::Runner.run("#{cf_bin} env #{app}") do |runner|
        expect(runner).not_to say "DEVELOP_ON_CLOUD_FOUNDRY"
      end

      BlueShell::Runner.run("#{cf_bin} delete #{app}") do |runner|
        expect(runner).to say "Really delete #{app}?>"
        runner.send_keys "y"
        expect(runner).to say "Deleting #{app}... OK"
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
