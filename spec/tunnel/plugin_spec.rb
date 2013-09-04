require "spec_helper"

describe CFTunnelPlugin::Tunnel do
  describe "#tunnel_clients" do
    context "when the user has a custom clients.yml in their cf directory" do
      it "overrides the default client config with the user's customizations" do
        CF::CONFIG_DIR = "#{SPEC_ROOT}/fixtures/fake_home_dirs/with_custom_clients/.cf"

        expect(subject.tunnel_clients["postgresql"]).to eq({
          "psql" => {
            "command"=>"-h ${host} -p ${port} -d ${name} -U ${user} -w",
            "environment" => ["PGPASSWORD='dont_ask_password'"]
          }
        })
      end
    end

    context "when the user does not have a custom clients.yml" do
      it "returns the default client config" do
        subject.stub(:config_file_path) { File.expand_path("./.cf/#{CFTunnelPlugin::Tunnel::CLIENTS_FILE}") }

        expect(subject.tunnel_clients["postgresql"]).to eq({
          "psql" => {
            "command"=>"-h ${host} -p ${port} -d ${name} -U ${user} -w",
            "environment" => ["PGPASSWORD='${password}'"]
          }
        })
      end
    end
  end
end
