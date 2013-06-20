require "spec_helper"

module CF
  module App
    describe Events do
      let(:global) { {} }
      let(:given) { {} }
      let(:inputs) { {:app => apps[0]} }
      let(:apps) { [build(:app)] }

      before do
        inputs[:app].stub(:events) do
          { "0" => {
            :instance_guid => "some_guid",
            :instance_index => 1,
            :exit_status => -1,
            :exit_description => "Something very interesting",
            :timestamp => "2013-05-15 18:52:15 +0000"
          }
          }
        end
      end

      subject do
        capture_output { Mothership.new.invoke(:events, inputs, given, global) }
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:events] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Display application events" }
          it { expect(Mothership::Help.group(:apps, :info)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has arguments that are not needed with a manifest" do
            should eq([:name => :app, :type => :optional, :value => nil])
          end
        end
      end

      it "prints out progress" do
        subject
        stdout.rewind
        expect(stdout.readlines.first).to match /Getting events for #{apps.first.name}/
      end

      it "prints out headers" do
        subject
        stdout.rewind
        expect(stdout.readlines[2]).to match /time\s+instance\s+index\s+description\s+exit\s+status/
      end

      it "prints out the events" do
        subject
        stdout.rewind
        expect(stdout.readlines.last).to match /.*2013-05-15 18:52:15 \+0000\s+1\s+Something very interesting\s+Failure \(-1\).*/
      end
    end
  end
end
