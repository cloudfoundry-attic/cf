require "spec_helper"

module CF::Space
  class Base; def fake_method; end
  end
end

module CF
  module Space
    describe Base do
      describe "#run" do
        subject { CF::Space::Base.new }

        it "uses a populator to set organization" do
          organization = double
          CF::Populators::Organization.should_receive(:new) { double(:populator, :populate_and_save! => organization) }
          subject.run(:fake_method)
          subject.org.should == organization
        end
      end

      describe ".space_by_name" do
        subject { CF::Space::Base.space_by_name }
        let(:org) { double(:organization) }

        before do
          org.should_receive(:space_by_name).with("mySpace").and_return(space)
        end


        context "with a space" do
          let(:space) { double(:space) }
          it "returns a space matching the name from the given org" do
            CF::Space::Base.space_by_name.call("mySpace", org).should == space
          end
        end

        context "with no matching space" do
          let(:space) { nil }
          it "fails when no space matches the name" do
            expect {
              CF::Space::Base.space_by_name.call("mySpace", org)
            }.to raise_exception
          end
        end
      end
    end
  end
end
