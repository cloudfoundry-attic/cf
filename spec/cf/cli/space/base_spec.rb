require 'spec_helper'
require "cf/cli/app/base"
require "pry-debugger"

describe CF::Space::Base do
  describe '#run' do
    subject { CF::Space::Base.new }

    it "uses a populator to set organization" do
      org = stub
      mock(CF::Populators::Organization).new(instance_of(Mothership::Inputs)) { stub!.populate_and_save! { org } }
      stub(subject).send()

      subject.run(:some_command)
      subject.org.should == org
    end
  end

  describe '.space_by_name' do
    subject { CF::Space::Base::space_by_name }
    let(:org) do
      Object.new.tap do |o|
        mock(o).space_by_name("mySpace").returns(space)
      end
    end

    context "with a space" do
      let(:space) { mock }
      it "returns a space matching the name from the given org" do
        subject.call("mySpace", org).should == space
      end
    end

    context "with no matching space" do
      let(:space) { nil }
      it "fails when no space matches the name" do
        expect {
          subject.call("mySpace", org)
        }.to raise_exception
      end
    end
  end
end
