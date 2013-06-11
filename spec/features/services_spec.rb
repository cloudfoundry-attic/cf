require "spec_helper"

if ENV['CF_V2_RUN_INTEGRATION']
  describe "Services" do
    before do
      login
    end

    describe "creating a service" do
      describe "when the user leaves the line blank for a plan" do
        let(:services) { [selected_service] }

        it "re-prompts for the plan" do
          BlueShell::Runner.run("#{cf_bin} create-service") do |runner|
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
    end
  end
end
