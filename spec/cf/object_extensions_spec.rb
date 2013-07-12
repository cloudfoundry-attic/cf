require "spec_helper"

describe "try" do
  it "calls through with arguments on non-nil objects" do
    "hi".try(:sub, 'i', 'o').should == "ho"
  end

  it "it throws a no method found error if the method does not exist" do
    expect {
      "hi".try(:fake_method)
    }.to raise_error(NoMethodError)
  end

  it "returns nil for nil" do
    nil.try(:sub, 'i', 'o').should == nil
  end
end