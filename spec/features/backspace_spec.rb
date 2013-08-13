require "spec_helper"
require "webmock/rspec"

if ENV['CF_V2_RUN_INTEGRATION']
  describe "A user pushing a new sinatra app", :ruby19 => true do
    let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
    let(:app) { "hello-sinatra-#{run_id}" }

    before do
      FileUtils.rm_rf File.expand_path(CF::CONFIG_DIR)
      login
    end

    after do
      `#{cf_bin} delete #{app} -f --routes --no-script`
    end

    it "attempts to use the backspace key" do
      Dir.chdir("#{SPEC_ROOT}/assets/hello-sinatra") do
        FileUtils.rm("manifest.yml", force: true)
        BlueShell::Runner.run("#{cf_bin} push #{app}") do |runner|
          expect(runner).to say "Instances> 1"
          runner.send_return

          expect(runner).to say "Memory Limit>"
          runner.send_keys "128M"

          expect(runner).to say "Creating #{app}... OK"

          expect(runner).to say "Subdomain> #{app}"
          app.length.times { runner.send_right_arrow }
          runner.send_backspace
          runner.send_return

          expect(runner).to say "Domain>"
          runner.send_return

          expect(runner).to say /Binding #{app[0..-2]}\..* to #{app}.*OK/, 1
        end
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide environment variables'
end

