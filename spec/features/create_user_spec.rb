require "spec_helper"
require "webmock/rspec"
require "ffaker"

if ENV['CF_V2_RUN_INTEGRATION']
  describe 'A new user tries to use CF against v2 production', :ruby19 => true do
    before(:all) do
      WebMock.allow_net_connect!
    end

    after(:all) do
      WebMock.disable_net_connect!
    end

    let(:target) { ENV['CF_V2_TEST_TARGET'] }
    let(:username) { ENV['CF_V2_TEST_USER'] }
    let(:password) { ENV['CF_V2_TEST_PASSWORD'] }
    let(:organization) { ENV['CF_V2_TEST_ORGANIZATION'] }

    let(:client) do
      client = CFoundry::V2::Client.new("https://#{target}")
      client.login(:username => username, :password => password)
      client
    end

    let(:new_user) { Faker::Internet.disposable_email("cf-test-user-#{Time.now.to_i}") }

    before do
      Interact::Progress::Dots.start!
      login
    end

    after do
      # TODO: do this when cf delete-user is implemented
      #BlueShell::Runner.run("#{cf_bin} delete-user #{email}") do |runner|
      #  expect(runner).to say "Really delete user #{email}?>"
      #  runner.send_keys "y"
      #  expect(runner).to say "Deleting #{email}... OK"
      #end

      # TODO: not this.
      client.login(:username => new_user, :password => password)
      user = client.current_user
      guid = user.guid
      client.login(:username => username, :password => password)
      user.delete!

      logout
      Interact::Progress::Dots.stop!
    end

    it "creates a new user" do
      BlueShell::Runner.run("#{cf_bin} create-user") do |runner|
        expect(runner).to say "Email>"
        runner.send_keys new_user

        expect(runner).to say "Password>"
        runner.send_keys password

        expect(runner).to say "Verify Password>"
        runner.send_keys password

        expect(runner).to say "Creating user... OK"
        expect(runner).to say "Adding user to #{organization}... OK"
      end

      BlueShell::Runner.run("#{cf_bin} login #{new_user} --password #{password}") do |runner|
        expect(runner).to say "Authenticating... OK"
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide environment variables'
end
