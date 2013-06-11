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

    let(:organization) { ENV['CF_V2_TEST_ORGANIZATION'] }
    let(:space) { ENV['CF_V2_TEST_SPACE'] }

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

    describe "needs cleanup after specs" do
      let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
      let(:app) { "hello-sinatra-recursive-#{run_id}" }
      let(:new_space) { "test-space-#{rand(10000)}" }
      let(:new_space_two) { "test-space-renamed-#{rand(10000)}" }

      after do
        begin
          BlueShell::Runner.run("#{cf_bin} delete-space #{new_space} -r -f")
        rescue
        end
        begin
          BlueShell::Runner.run("#{cf_bin} delete-space #{new_space_two} -r -f")
        rescue
        end
      end

      it "can create, switch, rename, and delete spaces" do
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

      it "can create an app in a space, then delete it recursively" do
        BlueShell::Runner.run("#{cf_bin} create-space #{new_space}") { |runner| runner.wait_for_exit(30) }
        BlueShell::Runner.run("#{cf_bin} switch-space #{new_space}") { |runner| runner.wait_for_exit(30) }

        push_app("hello-sinatra", app)

        BlueShell::Runner.run("#{cf_bin} delete-space #{new_space} --force") do |runner|
          expect(runner).to say("If you want to delete the space along with all dependent objects, rerun the command with the '--recursive' flag.")
          runner.wait_for_exit(30)
        end.should_not be_successful

        BlueShell::Runner.run("#{cf_bin} spaces") do |runner|
          expect(runner).to say(new_space)
          expect(runner).to say(app)
        end

        BlueShell::Runner.run("#{cf_bin} delete-space #{new_space} --recursive --force") do |runner|
          expect(runner).to say("Deleting space #{new_space}... OK")
        end

        BlueShell::Runner.run("#{cf_bin} spaces") do |runner|
          expect(runner).to_not say(new_space)
          expect(runner).to_not say(app)
        end
      end
    end

    it "shows all the spaces in the org" do
      BlueShell::Runner.run("#{cf_bin} spaces") do |runner|
        expect(runner).to say(space)
      end
    end

  end
end
