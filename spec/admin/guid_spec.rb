require "spec_helper"

describe CFAdmin::Guid do
  let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_admin_dir" }
  stub_home_dir_with { fake_home_dir }

  before do
    CFoundry::Client.any_instance.stub(:info) { { :version => 2 } }
  end

  let(:api_response) {{
    :total_results => 1,
    :total_pages => 1,
    :resources => [
      :metadata => {
        :guid => "guid",
      },
      :entity => {
        :name => "name",
      },
    ]
  }}

  def stub_api(path, response, opts={})
    stub = stub_request(:get, "https://api.some-target-for-cf-curl.com#{path}")
    response = MultiJson.dump(response) unless opts[:not_json]
    stub.to_return(:status => 200, :body => response)
  end

  context "when api returns >0 resources" do
    context "with known type" do
      let(:args) { ["guid", "--type", "organizations"] }

      it "shows results" do
        stub_api("/v2/organizations?", api_response)
        cf(args)
        expect(stdout.string).to match(/name.*guid/)
      end
    end

    context "with short known type" do
      let(:args) { ["guid", "--type", "or"] }

      it "shows results" do
        stub_api("/v2/organizations?", api_response)
        cf(args)
        expect(stdout.string).to match(/name.*guid/)
      end
    end

    context "with unknown type" do
      let(:args) { ["guid", "--type", "some-unknown-type"] }

      it "makes a request with unknown type" do
        stub_api("/v2/some-unknown-type?", api_response)
        cf(args)
        expect(stdout.string).to match(/name.*guid/)
      end
    end
  end

  context "when api returns 0 resources" do
    before do
      api_response[:total_results] = 0
      api_response[:total_pages] = 0
      api_response[:resources] = []
    end

    it "shows 0 results" do
      stub_api("/v2/organizations?", api_response)
      cf(["guid", "--type", "organizations"])
      expect(stdout.string).to match(/No results/)
    end
  end

  context "when api does not return resources (errors, etc.)" do
    ["", "not-json"].each do |response|
      it "shows unexpected response for api resonse '#{response}'" do
        stub_api("/v2/organizations?", response, :not_json => true)
        cf(["guid", "--type", "organizations"])
        expect(stdout.string).to match(/Unexpected response/)
      end
    end
  end
end
