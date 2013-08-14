require "spec_helper"

if ENV["CF_V2_RUN_INTEGRATION"]
  describe "creating and deleting orgs", ruby19: true do
    before(:all) { WebMock.allow_net_connect! }
    after(:all) { WebMock.disable_net_connect! }

    let(:run_id) { TRAVIS_BUILD_ID.to_s + Time.new.to_f.to_s.gsub(".", "_") }
    let(:new_org_name) { "new-org-#{run_id}" }

    before do
      Interact::Progress::Dots.start!
      login
    end

    after do
      logout
      Interact::Progress::Dots.stop!
    end

    it "can create and recursively delete an org" do
      BlueShell::Runner.run("#{cf_bin} create-org #{new_org_name}") do |runner|
        expect(runner).to say "Creating organization #{new_org_name}... OK"
        expect(runner).to say "Switching to organization #{new_org_name}... OK"
        expect(runner).to say "There are no spaces. You may want to create one with create-space."
      end

      BlueShell::Runner.run("#{cf_bin} create-space new-space") do |runner|
        expect(runner).to say "Creating space new-space... OK"
      end

      # TODO: pending until cc change 442f08e72c0808baf85b948a8b56e58f025edf72 is on a1
      #
      # BlueShell::Runner.run("cf delete-org #{new_org_name} --force") do |runner|
      #   expect(runner).to say "If you want to delete the organization along with" +
      #     " all dependent objects, rerun the command with the '--recursive' flag."
      # end

      BlueShell::Runner.run("#{cf_bin} delete-org #{new_org_name} --force --recursive") do |runner|
        expect(runner).to say "Deleting organization #{new_org_name}... OK", 15
      end

      BlueShell::Runner.run("#{cf_bin} target -o #{new_org_name}") do |runner|
        expect(runner).to say "Unknown organization '#{new_org_name}'."
      end
    end
  end
else
  $stderr.puts 'Skipping v2 integration specs; please provide necessary environment variables'
end
