require "spec_helper"

module CF
  describe "Help"  do
    let(:global) { {} }
    let(:given) { {} }
    let(:inputs) { {:app => apps[0]} }
    let(:apps) { [build(:app)] }


    subject do
      capture_output { Mothership.new.invoke(:help) }
    end

    it "prints the cf version in the first line" do
      subject
      stdout.rewind
      expect(stdout.readlines.first).to match /Cloud Foundry Command Line Interface, version \[#{CF::VERSION}\]\n/
    end
  end
end
