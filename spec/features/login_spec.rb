require "spec_helper"

if ENV['CF_V2_RUN_INTEGRATION']
  describe 'A user logs in and switches spaces, after a different user has logged in', :ruby19 => true do

    let(:target) { ENV['CF_V2_TEST_TARGET'] }
    let(:username) { ENV['CF_V2_TEST_USER'] }
    let(:password) { ENV['CF_V2_TEST_PASSWORD'] }

    let(:second_username) { ENV['CF_V2_OTHER_TEST_USER'] }
    let(:second_organization) { ENV['CF_V2_OTHER_TEST_ORGANIZATION'] }
    let(:second_space) { ENV['CF_V2_OTHER_TEST_SPACE'] }
    let(:second_password) { ENV['CF_V2_OTHER_TEST_PASSWORD'] || ENV['CF_V2_TEST_PASSWORD'] }

    before do
      Interact::Progress::Dots.start!

      BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
        expect(runner).to say "Setting target"
        expect(runner).to say target
        runner.wait_for_exit
      end

      BlueShell::Runner.run("#{cf_bin} logout") do |runner|
        runner.wait_for_exit
      end
    end

    after do
      Interact::Progress::Dots.stop!
    end

    context "when a different user is already logged in" do
      before do
        BlueShell::Runner.run("#{cf_bin} login #{username} --password #{password}") do |runner|
          expect(runner).to say "Authenticating... OK"

          expect(runner).to say(
            "Organization>" => proc {
              runner.send_keys "1"
              expect(runner).to say /Switching to organization .*\.\.\. OK/
            },
            "Switching to organization" => proc {}
          )

          expect(runner).to say(
            "Space>" => proc {
              runner.send_keys "1"
              expect(runner).to say /Switching to space .*\.\.\. OK/
            },
            "Switching to space" => proc {}
          )

          runner.wait_for_exit
        end
      end

      it "can switch spaces on login" do
        BlueShell::Runner.run("#{cf_bin} login #{second_username} --password #{second_password} --organization #{second_organization} --space #{second_space}") do |runner|
          expect(runner).to say "Authenticating... OK"
          expect(runner).to say "Switching to organization #{second_organization}... OK"
          expect(runner).to say "Switching to space #{second_space}... OK"
          runner.wait_for_exit
        end
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
