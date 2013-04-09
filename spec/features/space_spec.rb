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
    let(:space) { ENV['CF_V2_TEST_SPACE'] }

    let(:client) do
      client = CFoundry::V2::Client.new("https://#{target}")
      client.login(username, password)
      client
    end

    before do
      Interact::Progress::Dots.start!
      login
    end

    after do
      logout
      Interact::Progress::Dots.stop!
    end

    it "can get space info" do
      BlueShell::Runner.run("#{cf_bin} space #{space} --no-quiet") do |runner|
        expect(runner).to say("#{space}:\n")
        expect(runner).to say("organization: #{organization}")
      end
    end

    it "can create, switch, rename, and delete spaces" do
      new_space = "test-space-#{rand(10000)}"
      new_space_two = "test-space-renamed-#{rand(10000)}"
      BlueShell::Runner.run("#{cf_bin} create-space #{new_space}") do |runner|
        expect(runner).to say("Creating space #{new_space}... OK")
      end

      BlueShell::Runner.run("#{cf_bin} switch-space #{new_space}") do |runner|
        expect(runner).to say("Switching to space #{new_space}... OK")
      end

      BlueShell::Runner.run("#{cf_bin} rename-space #{new_space} #{new_space_two}") do |runner|
        expect(runner).to say("Renaming to #{new_space_two}... OK")
      end

      BlueShell::Runner.run("#{cf_bin} delete-space #{new_space_two}") do |runner|
        expect(runner).to say("Really delete")
        runner.send_keys "y"

        expect(runner).to say("Deleting space #{new_space_two}... OK")
      end
    end

    it "shows all the spaces in the org" do
      BlueShell::Runner.run("#{cf_bin} spaces") do |runner|
        expect(runner).to say(space)
      end
    end
  end
end
