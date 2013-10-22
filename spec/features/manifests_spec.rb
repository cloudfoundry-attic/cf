require "spec_helper"
require "webmock/rspec"

if ENV["CF_V2_RUN_INTEGRATION"]
  describe "A user pushing a new sinatra app" do

    let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
    let(:app) { "hello-sinatra-#{run_id}" }
    let(:subdomain) { "hello-sinatra-subdomain-#{run_id}" }
    let(:user_provided_name) { "user-provided-#{run_id}"}

    before do
      FileUtils.rm_rf File.expand_path(CF::CONFIG_DIR)
      WebMock.allow_net_connect!
      login
    end

    after do
      `#{cf_bin} unbind-service -f --no-script #{user_provided_name} #{app}`
      `#{cf_bin} delete-service -f --no-script #{user_provided_name}`

      `#{cf_bin} delete #{app} -f --routes --no-script`
      logout
    end

    context "with user-provided service" do
      it "reads the manifest when pushing" do
        Dir.chdir("#{SPEC_ROOT}/assets/hello-sinatra") do
          FileUtils.rm("manifest.yml", force: true)
          File.open("manifest.yml", "w") do |f|
            f.write(<<-MANIFEST)
---
applications:
- name: #{app}
  memory: 256M
  instances: 1
  host: #{subdomain}
  domain: cfapps.io
  path: .
  services:
    #{user_provided_name}:
      label: user-provided
      credentials:
        username: abc123
        password: sunshine
        hostname: oracle.enterprise.com
        port: 1234
        name: myoracledb2
            MANIFEST
          end

          BlueShell::Runner.run("#{cf_bin} push") do |runner|
            expect(runner).to say "Using manifest file manifest.yml"
            expect(runner).to say "Creating #{app}... OK"

            expect(runner).to say(/Creating route #{subdomain}\..*\.\.\. OK/)
            expect(runner).to say(/Binding #{subdomain}\..* to #{app}\.\.\. OK/)

            expect(runner).to say /Creating service #{user_provided_name}.*OK/
            expect(runner).to say /Binding #{user_provided_name} to #{app}... OK/

            expect(runner).to say "Uploading #{app}... OK", 180
            expect(runner).to say "Preparing to start #{app}... OK", 180
            expect(runner).to say "Checking status of app '#{app}'...", 180
            expect(runner).to say "1 of 1 instances running"
            expect(runner).to say "Push successful! App '#{app}' available at #{subdomain}.cfapps.io", 30
          end
        end

        BlueShell::Runner.run("#{cf_bin} services") do |runner|
          expect(runner).to say /name\s+service\s+provider\s+version\s+plan\s+bound apps/
          expect(runner).to say /#{user_provided_name}\s+ # name
            user-provided\s+                        # service
            n\/a\s+                              # provider
            n\/a\s+                             # version
            n\/a\s+                             # plan
            #{app}                              # bound apps
          /x
        end
      end
    end

  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
