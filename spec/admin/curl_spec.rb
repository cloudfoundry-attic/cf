require "spec_helper"

describe CFAdmin::Curl do
  let(:fake_home_dir) { "#{SPEC_ROOT}/fixtures/fake_admin_dir" }

  stub_home_dir_with { fake_home_dir }

  let(:client) { fake_client }

  context "when the response is JSON" do
    it "pretty-prints the response" do
      stub_request(:get, "https://api.some-target-for-cf-curl.com/foo").to_return(
        :headers => {
          "content-type" => "application/json; charset=utf8"
        },
        :status => 200,
        :body => '{"foo":"bar"}'
      )

      cf %W[curl GET /foo]
      expect(output).to say(<<OUT)
{
  "foo": "bar"
}
OUT
    end
  end

  context "with an implicit target" do
    it "makes a request to the current target" do
      stub_request(:get, "https://api.some-target-for-cf-curl.com/apps/5/instances").to_return(
        :status => 200,
        :body => 'some-body'
      )

      cf %W[curl GET /apps/5/instances]
      expect(output).to say("some-body")
    end
  end

  context "with an explicit target" do
    it "makes a request to the given target" do
      stub_request(:get, "https://some-other-domain.com/apps/5/instances").to_return(
        :status => 200,
        :body => 'some-other-body'
      )

      cf %W[curl GET https://some-other-domain.com/apps/5/instances]
      expect(output).to say("some-other-body")
    end
  end
end
