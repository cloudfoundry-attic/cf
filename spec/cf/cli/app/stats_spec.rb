require "spec_helper"

module CF
  module App
    describe Stats do
      let(:global) { {} }
      let(:given) { {} }
      let(:inputs) { {:app => apps[0]} }
      let(:apps) { [build(:app)] }

      before do
        inputs[:app].stub(:stats) do
          {"0" => {
            :state => "RUNNING",
            :stats => {
              :name => "basic_app",
              :uris => ["basic_app.p01.rbconsvcs.com"],
              :host => "172.20.183.93",
              :port => 61006,
              :uptime => 3250,
              :mem_quota => 301989888,
              :disk_quota => 268435456,
              :fds_quota => 256,
              :usage => {
                :time => "2013-01-04 19:53:39 +0000",
                :cpu => 0.0019777013519415455,
                :mem => 31395840,
                :disk => 15638528
              }
            }
          }
          }
        end
      end

      subject do
        capture_output { Mothership.new.invoke(:stats, inputs, given, global) }
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:stats] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Display application instance status" }
          it { expect(Mothership::Help.group(:apps, :info)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has no arguments" do
            should eq([:name => :app, :type => :optional, :value => nil])
          end
        end
      end

      it "prints out the stats" do
        subject
        stdout.rewind
        expect(stdout.readlines.last).to match /.*0\s+0\.0%\s+29\.9M of 288M\s+14\.9M of 256M.*/
      end
    end
  end
end
