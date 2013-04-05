shared_examples_for "a_command_that_populates_organization" do
  it "calls the organization populator" do
    mock(CF::Populators::Organization).new(instance_of(Mothership::Inputs)) { mock!.populate_and_save! }
    subject
  end
end