require "spec_helper"

module CF
  module Organization
    describe "Help"  do
      let(:global) { {} }
      let(:given) { {} }

      subject do
        capture_output { Mothership.new.invoke(:help, :command => "org") }
      end

      it "describes the command" do
        subject
        stdout.rewind
        expect(stdout.readlines.first).to match /Show organization information/
      end

      it "prints the options" do
        subject
        stdout.rewind
        expect(stdout.readlines.any? {|line| line =~ /Options:/ }).to be_true

      end

      context "when the user is not logged in" do
        before do
          capture_output { Mothership.new.invoke(:logout) }
        end

        it "does not require login" do
          subject
          stdout.rewind
          expect(stdout.readlines.first).to_not match /Please log in first to proceed/
        end
      end
    end
  end
end
