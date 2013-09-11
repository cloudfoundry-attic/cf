require "spec_helper"

describe "Service Brokers" do
  let(:broker_url) { 'http://broker.example.com/' }
  let(:broker_token) { 'opensesame' }
  let(:last_request) { FakeCloudController.last_request }

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

    @crash_log = File.join(@homedir, '.cf', 'crash')
    FileUtils.rm_f(@crash_log)
  end

  after do
    if File.exists?(@crash_log)
      puts `cat #{@crash_log}`
    end

    FakeCloudController.reset
  end

  it "allows an admin user to add a service broker" do
    BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} add-service-broker --name my-custom-service --url #{broker_url} --token #{broker_token}") do |runner|
      expect(runner).to say "Adding service broker my-custom-service... OK"
    end

    expect(last_request).to be_post
    expect(last_request.path).to eq('/v2/service_brokers')
    expect(JSON.load(last_request.body)).to eq(
      'name' => 'my-custom-service',
      'broker_url' => broker_url,
      'token' => broker_token
    )
  end

  it "allows an admin user to list service brokers" do
    BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} service-brokers") do |runner|
      expect(runner).to say /my-custom-service.*#{broker_url}/
    end

    expect(last_request).to be_get
    expect(last_request.path).to eq('/v2/service_brokers')
  end

  it "allows an admin user to remove a service broker" do
    BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} remove-service-broker my-custom-service") do |runner|
      expect(runner).to say "Really remove my-custom-service?> n"
      runner.send_keys("y")
      expect(runner).to say "Removing service broker my-custom-service... OK"
    end

    expect(last_request).to be_delete
    expect(last_request.path).to eq('/v2/service_brokers/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
  end

  it "allows an admin user to update a service broker" do
    BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} update-service-broker my-custom-service --name cf-othersql --url http://other.example.com/ --token othertoken") do |runner|
      expect(runner).to say "Updating service broker my-custom-service... OK"
    end

    expect(last_request).to be_put
    expect(last_request.path).to eq('/v2/service_brokers/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
  end
end
