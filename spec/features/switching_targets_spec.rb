require "spec_helper"

if ENV['CF_V2_RUN_INTEGRATION']
  describe 'A new user tries to use CF against v2 production', ruby19: true do

    let(:target) { ENV['CF_V2_TEST_TARGET'] }
    let(:space) { ENV['CF_V2_TEST_SPACE'] }
    let(:space_2) { "#{ENV['CF_V2_TEST_SPACE']}-2"}
    let(:organization_2) { ENV['CF_V2_TEST_ORGANIZATION_TWO'] }

    let(:created_space_1) { "space-#{rand(10000)}"}
    let(:created_space_2) { "space-#{rand(10000)}"}

    before do
      target_file = File.expand_path("~/.cf/target")
      FileUtils.rm(target_file) if File.exists? target_file
      Interact::Progress::Dots.start!
    end

    after do
      logout
      Interact::Progress::Dots.stop!
    end

    it "can switch targets, even if a target is invalid" do
      BlueShell::Runner.run("#{cf_bin} target") do |runner|
        expect(runner).to say "  CF instance: N/A"
      end

      BlueShell::Runner.run("#{cf_bin} target invalid-target") do |runner|
        expect(runner).to say "Target refused"
        runner.wait_for_exit
      end

      BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
        expect(runner).to say "Setting target"
        expect(runner).to say target
        runner.wait_for_exit
      end
    end

    context "with created spaces in the second org" do
      it "can switch organizations and spaces" do
        login

        BlueShell::Runner.run("#{cf_bin} target -o #{organization_2}") do |runner|
          expect(runner).to say "Switching to organization #{organization_2}"
          expect(runner).to say "Space>"
          runner.send_keys space_2

          expect(runner).to say(/Switching to space #{space_2}/)

          runner.wait_for_exit 15
        end

        BlueShell::Runner.run("#{cf_bin} target -s #{space}") do |runner|
          expect(runner).to say("Switching to space #{space}")
          runner.wait_for_exit 15
        end

        BlueShell::Runner.run("#{cf_bin} target -s #{space_2}") do |runner|
          expect(runner).to say("Switching to space #{space_2}")
          runner.wait_for_exit 15
        end
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
