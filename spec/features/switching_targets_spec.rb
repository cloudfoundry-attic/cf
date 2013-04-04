require "spec_helper"

if ENV['CF_V2_TEST_TARGET']
  describe 'A new user tries to use CF against v2 production', :ruby19 => true do
    include ConsoleAppSpeckerMatchers

    let(:target) { ENV['CF_V2_TEST_TARGET'] }
    let(:username) { ENV['CF_V2_TEST_USER'] }
    let(:password) { ENV['CF_V2_TEST_PASSWORD'] }
    let(:organization) { ENV['CF_V2_TEST_ORGANIZATION'] }

    before do
      Interact::Progress::Dots.start!
    end

    after do
      Interact::Progress::Dots.stop!
    end

    it "can switch targets, even if a target is invalid" do
      run("#{cf_bin} target invalid-target") do |runner|
        expect(runner).to say "Target refused"
        runner.wait_for_exit
      end

      run("#{cf_bin} target #{target}") do |runner|
        expect(runner).to say "Setting target"
        expect(runner).to say target
        runner.wait_for_exit
      end
    end

    it "can switch organizations and spaces" do
      run("#{cf_bin} login") do |runner|
        expect(runner).to say "Email>"
        runner.send_keys username

        expect(runner).to say "Password>"
        runner.send_keys password

        expect(runner).to say "Authenticating... OK"
      end

      run("#{cf_bin} target -o #{organization}") do |runner|
        expect(runner).to say("Switching to organization #{organization}")
        runner.wait_for_exit
      end

      run("#{cf_bin} target -s staging") do |runner|
        expect(runner).to say("Switching to space staging")
        runner.wait_for_exit
      end
      run("#{cf_bin} target -s production") do |runner|
        expect(runner).to say("Switching to space production")
        runner.wait_for_exit
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
