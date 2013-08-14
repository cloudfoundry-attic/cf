require "spec_helper"

describe "Service Broker Management", components: [:nats, :uaa, :ccng, :fake_service_broker] do
  let(:username) { 'admin' }
  let(:password) { 'the_admin_pw' }
  let(:target) { 'http://127.0.0.1:8181' }

  let(:broker_url) { 'http://127.0.0.1:54329' }
  let(:broker_token) { 'opensesame' }

  before do
    create_user_in_ccng
    logout

    BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
      runner.wait_for_exit
      expect(runner).to be_successful
    end

    BlueShell::Runner.run("#{cf_bin} login #{username} --password #{password}") do |runner|
      expect(runner).to say "Authenticating... OK"
    end
  end

  after do
    logout
  end

  it "allows an admin user to add a service broker" do
    BlueShell::Runner.run("#{cf_bin} add-service-broker --name my-custom-service --url #{broker_url} --token #{broker_token}") do |runner|
      expect(runner).to say "Adding service broker my-custom-service... OK"
    end
  end

  context "with a service broker already registered" do
    before do
      BlueShell::Runner.run("#{cf_bin} add-service-broker --name my-custom-service --url #{broker_url} --token #{broker_token}") do |runner|
        expect(runner).to say "Adding service broker my-custom-service... OK"
      end
    end

    it "allows an admin user to list service brokers" do
      BlueShell::Runner.run("#{cf_bin} service-brokers") do |runner|
        expect(runner).to say /my-custom-service.*#{broker_url}/
      end
    end

    it "allows an admin user to remove a service broker" do
      BlueShell::Runner.run("#{cf_bin} remove-service-broker my-custom-service") do |runner|
        expect(runner).to say "Really remove my-custom-service?> n"
        runner.send_keys("y")
        expect(runner).to say "Removing service broker my-custom-service... OK"
      end

      BlueShell::Runner.run("#{cf_bin} service-brokers") do |runner|
        expect(runner).to_not say /my-custom-service/
      end
    end
  end

  def create_user_in_ccng
    ccng_post "/v2/users", {
      guid: user_guid
    }
  end

  def user_guid
    uaa_port = component!(:uaa).port
    token_issuer = CF::UAA::TokenIssuer.new("http://localhost:#{uaa_port}", 'cf')
    auth_header = token_issuer.owner_password_grant(username, password).auth_header
    response = Typhoeus::Request.new(
      "http://localhost:#{uaa_port}/Users?filter=userName+eq+'#{username}'",
      headers: {'Authorization' => auth_header}
    ).run
    JSON.parse(response.body).fetch("resources").first.fetch('id')
  end
end
