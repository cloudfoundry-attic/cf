require "spec_helper"
require "webmock/rspec"
require "cf/cli/populators/target"

describe CF::Populators::Target do
  describe "#populate_and_save!" do
    let(:input) { stub! }
    let(:organization) { stub! }

    subject { CF::Populators::Target.new(input).populate_and_save! }

    it "uses a organization then a space populator" do
      mock(CF::Populators::Organization).new(input) { mock!.populate_and_save! { organization } }
      mock(CF::Populators::Space).new(input, organization) { mock!.populate_and_save! }
      subject
    end
  end
end