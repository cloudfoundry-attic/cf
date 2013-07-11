require "spec_helper"

module CF
  module Organization
    describe Orgs do
      let(:global) { {:color => false} }
      let(:inputs) { {} }
      let(:given) { {} }
      let(:output) { StringIO.new }

      let(:client) { build(:client) }
      let(:space) { build(:space) }
      let(:domain) { build(:domain) }
      let!(:org_1) { build(:organization, :name => "bb_second", :spaces => [space], :domains => [domain]) }
      let!(:org_2) { build(:organization, :name => "aa_first", :spaces => [space], :domains => [domain]) }
      let!(:org_3) { build(:organization, :name => "cc_last", :spaces => [space], :domains => [domain]) }
      let(:organizations) { [org_1, org_2, org_3] }

      before do
        CF::CLI.any_instance.stub(:client) { client }
        CF::CLI.any_instance.stub(:precondition) { nil }

        client.stub(:organizations).and_return(organizations)
      end

      subject do
        capture_output { Mothership.new.invoke(:orgs, inputs, given, global) }
      end

      describe "metadata" do
        let(:command) { Mothership.commands[:orgs] }

        describe "command" do
          subject { command }
          its(:description) { should eq "List available organizations" }
          it { expect(Mothership::Help.group(:organizations)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has no arguments" do
            should be_empty
          end
        end
      end

      it "should have the correct first two lines" do
        subject
        stdout.rewind
        expect(stdout.readline).to match /Getting organizations.*OK/
        expect(stdout.readline).to eq "\n"
      end

      context "when there are no organizations" do
        let(:organizations) { [] }

        context "and the full flag is given" do
          let(:inputs) { {:full => true} }

          it "displays yaml-style output with all organization details" do
            CF::Organization::Orgs.any_instance.should_not_receive(:invoke)
            subject
          end
        end

        context "and the full flag is not given (default is false)" do
          it "should show only the progress" do
            subject

            stdout.rewind
            expect(stdout.readline).to match /Getting organizations.*OK/
            expect(stdout).to be_eof
          end
        end
      end

      context "when there are organizations" do
        context "and the full flag is given" do
          let(:inputs) { {:full => true} }

          it "displays yaml-style output with all organization details" do
            CF::Organization::Orgs.any_instance.should_receive(:invoke).with(:org, :organization => org_2, :full => true)
            CF::Organization::Orgs.any_instance.should_receive(:invoke).with(:org, :organization => org_1, :full => true)
            CF::Organization::Orgs.any_instance.should_receive(:invoke).with(:org, :organization => org_3, :full => true)
            subject
          end
        end

        context "and the full flag is not given (default is false)" do

          before do
            org_1.stub(:spaces).and_return([space])
            org_2.stub(:spaces).and_return([space])
            org_3.stub(:spaces).and_return([space])
          end

          it "displays tabular output with names, spaces and domains" do
            subject

            stdout.rewind
            stdout.readline
            stdout.readline

            expect(stdout.readline).to match /name/
            organizations.sort_by(&:name).each do |org|
              expect(stdout.readline).to match /#{org.name}/
            end
            expect(stdout).to be_eof
          end
        end
      end
    end
  end
end
