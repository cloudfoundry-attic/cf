require "spec_helper"

describe "Services" do
  def login(opts = {})
    File.open(File.join(@homedir, '.cf', 'tokens.yml'), 'w') do |f|
      f.puts <<-YAML
http://127.0.0.1:12345:
  :version: 2
  :token: bearer eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI0MGE0YWJlOS0yYTgxLTQyZGYtODVjNS1kNDdlMzRiOTA0YTEiLCJ1c2VyX2lkIjoiMzI5YmIzYmYtMWU3NS00MGQ3LThhMDItMjI3Y2FjY2IyZGU3Iiwic3ViIjoiMzI5YmIzYmYtMWU3NS00MGQ3LThhMDItMjI3Y2FjY2IyZGU3IiwidXNlcl9uYW1lIjoiYWRtaW4iLCJlbWFpbCI6ImFkbWluIiwic2NvcGUiOlsiY2xvdWRfY29udHJvbGxlci5hZG1pbiIsImNsb3VkX2NvbnRyb2xsZXIucmVhZCIsImNsb3VkX2NvbnRyb2xsZXIud3JpdGUiLCJvcGVuaWQiLCJwYXNzd29yZC53cml0ZSIsInNjaW0ucmVhZCIsInNjaW0ud3JpdGUiXSwiY2xpZW50X2lkIjoiY2YiLCJjaWQiOiJjZiIsImlhdCI6MTM3NjU5MzI3NiwiZXhwIjoxMzc2NjAwNDc2LCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvdWFhL29hdXRoL3Rva2VuIiwiYXVkIjpbInNjaW0iLCJvcGVuaWQiLCJjbG91ZF9jb250cm9sbGVyIiwicGFzc3dvcmQiXX0.VSPhFetKLDvZal8bOK38uTBbkrDD2_IdSjHqluk1WIY
  :space: #{opts.fetch(:space_guid)}
  :organization: 57944537-4f45-424d-a8af-b41ab6b4f0a0
      YAML
    end
  end

  before do
    thr = Thread.new do
      Rack::Handler::WEBrick.run(FakeCloudController, :Port => 12345, :AccessLog => [], :Logger => WEBrick::Log::new(nil, 0))
    end

    def responsive?
      begin
        resp = Net::HTTP.start('localhost', 12345) { |http| http.get('/responsive') }
        resp.is_a? Net::HTTPSuccess
      rescue Errno::ECONNREFUSED
        false
      end
    end

    Timeout.timeout(60) { thr.join(0.1) until responsive? }

    @homedir = File.join(File.dirname(__FILE__), '..', '..', 'tmp')
    FileUtils.mkdir_p(File.join(@homedir, '.cf'))

    # cf target
    File.open(File.join(@homedir, '.cf', 'target'), 'w') do |f|
      f.puts 'http://127.0.0.1:12345'
    end

    # cf login
    login(space_guid: '671847d5-9754-49b2-bc9f-977ee42c7e4c')

    @crash_log = File.join(@homedir, '.cf', 'crash')
    FileUtils.rm_f(@crash_log)
  end

  after do
    if File.exists?(@crash_log)
      puts `cat #{@crash_log}`
    end

    FakeCloudController.reset
  end

  describe "listing services" do
    let(:service1) { "some-provided-instance" }
    let(:service2) { "cf-managed-instance" }

    it "shows all service instances in the space" do
      BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} services") do |runner|
        expect(runner).to say /#{service1}\s+user-provided\s+n\/a\s+n\/a\s+n\/a\s+.*/
      end
    end
  end

  describe "creating a service" do
    describe "when the user leaves the line blank for a plan" do
      it "re-prompts for the plan" do
        BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} create-service") do |runner|
          expect(runner).to say "What kind?"
          runner.send_keys "1"
          expect(runner).to say "Name?"
          runner.send_return
          expect(runner).to say "Which plan?"
          runner.send_return
          expect(runner).to say "Which plan?"
        end
      end
    end

    describe "when the service is a user-provided instance" do
      let(:service_name) { "my-private-db"}

      it "can create a service instance" do
        BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} create-service") do |runner|
          expect(runner).to say "What kind?"
          runner.send_keys "user-provided"

          expect(runner).to say "Name?"
          runner.send_keys service_name

          expect(runner).to say "What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)"
          runner.send_keys "hostname"
          expect(runner).to say "hostname"
          runner.send_keys "myserviceinstance.com"

          expect(runner).to say /Creating service #{service_name}.+ OK/
        end
      end
    end

    context "when the space has access to the service" do
      before do
        login(space_guid: '671847d5-9754-49b2-bc9f-deadbeefdead')
      end

      it "successfully creates the service" do
        BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} create-service") do |runner|
          expect(runner).to say "What kind?"
          runner.send_keys "private-service"
          expect(runner).to say "Name?"
        end
      end
    end

    context "when the space does not have access to the service" do
      it "displays an error" do
        BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} create-service") do |runner|
          expect(runner).to say "What kind?"
          runner.send_keys "private-service"
          expect(runner).to say "Unknown answer, please try again!"
        end
      end
    end
  end

  describe "binding to a service" do
    let(:app_folder) { "env" }
    let(:app_name) { "services_env_test_app" }

    let(:service_name) { "some-provided-instance" }

    it "can bind and unbind user-provided services to apps" do
      BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} bind-service") do |runner|
        expect(runner).to say "Which application?>"
        runner.send_keys app_name

        expect(runner).to say "Which service?>"
        runner.send_keys service_name

        expect(runner).to say "Binding #{service_name} to #{app_name}... OK"
      end

      BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} unbind-service") do |runner|
        expect(runner).to say "Which application?"
        runner.send_keys app_name

        expect(runner).to say "Which service?>"
        runner.send_keys service_name

        expect(runner).to say "Unbinding #{service_name} from #{app_name}... OK"
      end
    end
  end
end

