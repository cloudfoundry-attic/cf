require "spec_helper"

describe "#try" do
  it "calls through with arguments on non-nil objects" do
    "hi".try(:sub, 'i', 'o').should == "ho"
  end

  it "yields to a provided block" do
    hash = {key: "value"}
    retrieved_key = nil
    retrieved_value = nil
    hash.try(:each) do |k, v|
      retrieved_key = k
      retrieved_value = v
    end

    retrieved_key.should == :key
    retrieved_value.should == "value"
  end

  it "returns nil for nil" do
    nil.try(:sub, 'i', 'o').should == nil
  end
end
