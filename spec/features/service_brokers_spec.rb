require "spec_helper"
require "sinatra"

class FakeCloudController < Sinatra::Base
  @requests = []

  class << self
    attr_accessor :requests

    def last_request
      requests.last
    end

    def reset
      requests.clear
    end
  end

  get '/v2/service_brokers' do
    self.class.requests << request

    broker_guid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    body = {
      'total_results' => 1,
      'total_pages' => 1,
      'prev_url' => nil,
      'next_url' => nil,
      'resources' => [{
        'metadata' => {
          'guid' => broker_guid,
          'url' => "http://cc.example.com/v2/service_brokers/#{broker_guid}",
          'created_at' => Time.now,
          'updated_at' => Time.now,
        },
        'entity' => {
          'name' => 'my-custom-service',
          'broker_url' => 'http://broker.example.com/',
        }
      }]
    }.to_json
    [200, {}, body]
  end

  post '/v2/service_brokers' do
    self.class.requests << request

    body = {
      metadata: {
        guid: SecureRandom.uuid
      }
    }.to_json

    [200, {}, body]
  end

  delete '/v2/service_brokers/:guid' do
    self.class.requests << request
    204
  end

  put '/v2/service_brokers/:guid' do
    self.class.requests << request
    201
  end

  get '/responsive' do
    200
  end
end

describe "Service Brokers" do
  let(:broker_url) { 'http://broker.example.com/' }
  let(:auth_username) { 'me' }
  let(:auth_password) { 'opensesame' }
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

    # cf login
    File.open(File.join(@homedir, '.cf', 'tokens.yml'), 'w') do |f|
      f.puts <<-YAML
http://127.0.0.1:8181:
  :version: 2
  :token: bearer eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI0MGE0YWJlOS0yYTgxLTQyZGYtODVjNS1kNDdlMzRiOTA0YTEiLCJ1c2VyX2lkIjoiMzI5YmIzYmYtMWU3NS00MGQ3LThhMDItMjI3Y2FjY2IyZGU3Iiwic3ViIjoiMzI5YmIzYmYtMWU3NS00MGQ3LThhMDItMjI3Y2FjY2IyZGU3IiwidXNlcl9uYW1lIjoiYWRtaW4iLCJlbWFpbCI6ImFkbWluIiwic2NvcGUiOlsiY2xvdWRfY29udHJvbGxlci5hZG1pbiIsImNsb3VkX2NvbnRyb2xsZXIucmVhZCIsImNsb3VkX2NvbnRyb2xsZXIud3JpdGUiLCJvcGVuaWQiLCJwYXNzd29yZC53cml0ZSIsInNjaW0ucmVhZCIsInNjaW0ud3JpdGUiXSwiY2xpZW50X2lkIjoiY2YiLCJjaWQiOiJjZiIsImlhdCI6MTM3NjU5MzI3NiwiZXhwIjoxMzc2NjAwNDc2LCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvdWFhL29hdXRoL3Rva2VuIiwiYXVkIjpbInNjaW0iLCJvcGVuaWQiLCJjbG91ZF9jb250cm9sbGVyIiwicGFzc3dvcmQiXX0.VSPhFetKLDvZal8bOK38uTBbkrDD2_IdSjHqluk1WIY
  :refresh_token: eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiI1MzA3ZGJmNC1iMTE1LTQ0MzgtOWRkNi00ZGVlMDVkZjgwN2IiLCJzdWIiOiIzMjliYjNiZi0xZTc1LTQwZDctOGEwMi0yMjdjYWNjYjJkZTciLCJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbImNsb3VkX2NvbnRyb2xsZXIuYWRtaW4iLCJjbG91ZF9jb250cm9sbGVyLnJlYWQiLCJjbG91ZF9jb250cm9sbGVyLndyaXRlIiwib3BlbmlkIiwicGFzc3dvcmQud3JpdGUiLCJzY2ltLnJlYWQiLCJzY2ltLndyaXRlIl0sImlhdCI6MTM3NjU5MzI3NiwiZXhwIjoxMzc3ODAyODc2LCJjaWQiOiJjZiIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODA4MC91YWEvb2F1dGgvdG9rZW4iLCJhdWQiOlsiY2xvdWRfY29udHJvbGxlci5hZG1pbiIsImNsb3VkX2NvbnRyb2xsZXIucmVhZCIsImNsb3VkX2NvbnRyb2xsZXIud3JpdGUiLCJvcGVuaWQiLCJwYXNzd29yZC53cml0ZSIsInNjaW0ucmVhZCIsInNjaW0ud3JpdGUiXX0.7wlsnXoBuE-jSYTBZboy1U26NWs4-VHBEYYGMLz5YFQ
  :space: 671847d5-9754-49b2-bc9f-977ee42c7e4c
  :organization: 57944537-4f45-424d-a8af-b41ab6b4f0a0
      YAML
    end
  end

  after do
    crash_log = File.join(@homedir, '.cf', 'crash')
    if File.exists?(crash_log)
      puts `cat #{crash_log}`
      FileUtils.rm(crash_log)
    end

    FakeCloudController.reset
  end

  it "allows an admin user to add a service broker" do
    BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} add-service-broker --name my-custom-service --url #{broker_url} --username #{auth_username} --password #{auth_password}") do |runner|
      expect(runner).to say "Adding service broker my-custom-service... OK"
    end

    expect(last_request).to be_post
    expect(last_request.path).to eq('/v2/service_brokers')
    expect(JSON.load(last_request.body)).to eq(
      'name' => 'my-custom-service',
      'broker_url' => broker_url,
      'auth_username' => auth_username,
      'auth_password' => auth_password,
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
    BlueShell::Runner.run("env HOME=#{@homedir} #{cf_bin} update-service-broker my-custom-service --name cf-othersql --url http://other.example.com/  --username newusername --password newpassword") do |runner|
      expect(runner).to say "Updating service broker my-custom-service... OK"
    end

    expect(last_request).to be_put
    expect(last_request.path).to eq('/v2/service_brokers/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
    expect(JSON.load(last_request.body)).to eq(
      'name' => 'cf-othersql',
      'broker_url' => 'http://other.example.com/',
      'auth_username' => 'newusername',
      'auth_password' => 'newpassword',
    )
  end
end
