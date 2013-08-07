require "spec_helper"
require "webmock/rspec"

if ENV["CF_V2_RUN_INTEGRATION"]
  describe "A user deleting an app bound to a user-provided service" do
    let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
    let(:app) { "hello-sinatra-#{run_id}" }
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

    it "can delete the user-provided service when given --delete-orphaned" do
      Dir.chdir("#{SPEC_ROOT}/assets/hello-sinatra") do
        FileUtils.rm("manifest.yml", force: true)
        File.open("manifest.yml", "w") do |f|
          f.write(<<-MANIFEST)
---
applications:
- name: #{app}
  memory: 256M
  instances: 1
  host: ~
  domain: none
  path: .
  services:
    #{user_provided_name}:
      label: user-provided
      credentials:
        username: abc123
          MANIFEST
        end

        BlueShell::Runner.run("#{cf_bin} push --no-start") do |runner|
          expect(runner).to say "Using manifest file manifest.yml"
          expect(runner).to say "Creating #{app}... OK"

          expect(runner).to say /Creating service #{user_provided_name}.*OK/
          expect(runner).to say /Binding #{user_provided_name} to #{app}... OK/

          expect(runner).to say "Uploading #{app}... OK"
        end
      end

      BlueShell::Runner.run("#{cf_bin} delete #{app} --delete-orphaned --force") do |runner|
        expect(runner).to say "Deleting #{app}... OK"
        expect(runner).to say "Deleting #{user_provided_name}... OK"
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
