require "spec_helper"

module CF
  module Populators
    describe Target do
      describe "#populate_and_save!" do
        let(:input) { double(:input) }
        let(:organization) { double(:organization) }
        let(:space) { double(:space) }

        subject { Target.new(input).populate_and_save! }

        it "uses a organization then a space populator" do
          organization.should_receive(:populate_and_save!).and_return(organization)
          space.should_receive(:populate_and_save!)
          Organization.should_receive(:new).with(input).and_return(organization)
          Space.should_receive(:new).with(input, organization).and_return(space)
          subject
        end
      end
    end
  end
end
