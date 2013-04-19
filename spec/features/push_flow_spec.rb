require "spec_helper"
require "webmock/rspec"

if ENV['CF_V2_RUN_INTEGRATION']
  describe 'A new user tries to use CF against v2', :ruby19 => true do
    include CF::Interactive

    let(:target) { ENV['CF_V2_TEST_TARGET'] }
    let(:username) { ENV['CF_V2_TEST_USER'] }
    let(:password) { ENV['CF_V2_TEST_PASSWORD'] }
    let(:organization) { ENV['CF_V2_TEST_ORGANIZATION_TWO'] }

    let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
    let(:app) { "hello-sinatra-#{run_id}" }
    let(:service_name) { "mysql-#{run_id}" }

    before do
      FileUtils.rm_rf File.expand_path(CF::CONFIG_DIR)
      WebMock.allow_net_connect!
      Interact::Progress::Dots.start!
      login
    end

    after do
      `#{cf_bin} unbind-service -f --no-script #{service_name} #{app}`
      `#{cf_bin} delete #{app} -f --routes --no-script`
      logout
      Interact::Progress::Dots.stop!
    end

    it 'pushes a simple sinatra app using defaults as much as possible' do
      BlueShell::Runner.run("#{cf_bin} app #{app}") do |runner|
        expect(runner).to say "Unknown app '#{app}'."
      end

      Dir.chdir("#{SPEC_ROOT}/assets/hello-sinatra") do
        BlueShell::Runner.run("#{cf_bin} push") do |runner|
          expect(runner).to say "Name>"
          runner.send_keys app

          expect(runner).to say "Instances> 1"
          runner.send_keys ""

          expect(runner).to say "Custom startup command> "
          runner.send_keys ""

          expect(runner).to say "Memory Limit>"
          runner.send_keys "128M"

          expect(runner).to say "Creating #{app}... OK"

          expect(runner).to say "Subdomain> #{app}"
          runner.send_keys ""

          expect(runner).to say "1:"
          expect(runner).to say "Domain>"
          runner.send_keys "1"

          expect(runner).to say(/Creating route #{app}\..*\.\.\. OK/)
          expect(runner).to say(/Binding #{app}\..* to #{app}\.\.\. OK/)

          expect(runner).to say "Create services for application?> n"
          runner.send_keys "y"

          # create a service here
          expect(runner).to say "What kind?>"
          runner.send_keys "mysql n/a"

          expect(runner).to say "Name?>"
          runner.send_keys service_name

          expect(runner).to say "Which plan?>"
          runner.send_keys "cfinternal"

          expect(runner).to say /Creating service #{service_name}.*OK/
          expect(runner).to say /Binding .+ to .+ OK/

          expect(runner).to say "Create another service?> n"
          runner.send_keys ""

          # skip this
          if runner.expect "Bind other services to application?> n", 15
            runner.send_keys ""
          end

          expect(runner).to say "Save configuration?> n", 20
          runner.send_keys ""

          expect(runner).to say "Uploading #{app}... OK", 180
          expect(runner).to say "Starting #{app}... OK", 180
          expect(runner).to say "Checking #{app}...", 180
          expect(runner).to say "1/1 instances"
          expect(runner).to say "OK", 30
        end
      end

      BlueShell::Runner.run("#{cf_bin} services") do |runner|
        expect(runner).to say /name\s+service\s+provider\s+version\s+plan\s+bound apps/
        expect(runner).to say /mysql-.+?\s+   # name
            mysql\s+                          # service
            aws\s+                            # provider
            n\/a\s+                           # version
            cfinternal\s+                     # plan
            #{app}                            # bound apps
          /x
      end

      BlueShell::Runner.run("#{cf_bin} unbind-service #{service_name} #{app}") do |runner|
        runner.wait_for_exit(20)
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
