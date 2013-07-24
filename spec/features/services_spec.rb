require "spec_helper"

if ENV['CF_V2_RUN_INTEGRATION']
  describe "Services" do
    before do
      login
    end

    describe "listing services" do
      it "shows all service instances in the space" do
        pending "Need a test environment to run this against. A1 should soon contain the necessary changes - DS & RT"
        service1 = "some-provided-instance-#{Time.now.to_i}"
        service2 = "cf-managed-instance-#{Time.now.to_i}"
        create_service_instance("user-provided", service1, credentials: { hostname: "myservice.com"} )
        create_service_instance("1", service2, plan: "1")

        BlueShell::Runner.run("#{cf_bin} services") do |runner|
          expect(runner).to say /#{service1}\s+none\s+none\s+none\s+none\s+.*/
        end

      end
    end

    describe "creating a service" do
      describe "when the user leaves the line blank for a plan" do
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

      describe "when the service is a user-provided instance" do
        let(:service_name) { "my-private-db-#{Random.rand(1000) + 1000}"}

        it "can create a service instance" do
          pending "Need a test environment to run this against. A1 should soon contain the necessary changes - DS & RT"
          BlueShell::Runner.run("#{cf_bin} create-service") do |runner|
            expect(runner).to say "What kind?"
            runner.send_keys "user-provided"

            expect(runner).to say "Name?"
            runner.send_keys service_name

            expect(runner).to say "What credentials parameters should applications use to connect to this service instance? (e.g. key: uri, value: mysql://username:password@hostname:port/name)
Key"
            runner.send_keys "hostname"
            expect(runner).to say "Value"
            runner.send_keys "myserviceinstance.com"
            expect(runner).to say "Another credentials parameter?"
            runner.send_keys "n"

            expect(runner).to say /Creating service #{service_name}.+ OK/
          end
        end
      end
    end
  end
end
