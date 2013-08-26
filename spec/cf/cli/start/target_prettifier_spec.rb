require "spec_helper"

module CF::Start
  describe TargetPrettifier do
    let(:user) do
      build(:user).tap { |u| u.stub(:email => 'user@example.com') }
    end
    let(:space) { build(:space) }
    let(:organization) { build(:organization) }
    let(:target) { "http://example.com" }
    let(:client) do
      double(:client,
             target: target,
             current_user: user,
             current_organization: organization,
             current_space: space,
             version: 2
      )
    end
    let(:outputter) { double(:outputter, line: nil, fail: nil) }

    before do
      outputter.stub(:c) { |to_colorize| to_colorize }
    end

    describe "displaying the target (no args)" do
      it "prints things nicely" do
        TargetPrettifier.prettify(client, outputter)
        desired_result = <<-STR
Target Information (where will apps be pushed):
  CF instance: #{client.target} (API version: 2)
  user: #{user.email}
  target app space: #{space.name} (org: #{organization.name})
        STR
        desired_result.each_line do |line|
          outputter.should have_received(:line).with(line.chomp)
        end
      end

      context "when there is no target" do
        let(:target) { nil }
        it "displays 'N/A' as the value of the target" do
          desired_result = <<-STR
Target Information (where will apps be pushed):
  CF instance: N/A (API version: 2)
  user: #{user.email}
  target app space: #{space.name} (org: #{organization.name})
          STR

          desired_result.each_line do |line|
            outputter.should_receive(:line).with(line.chomp)
          end

          TargetPrettifier.prettify(client, outputter)
        end
      end

      context "when nothing is specified" do
        let(:user) { nil }
        let(:space) { nil }
        let(:organization) { nil }

        it "prints things nicely" do
          TargetPrettifier.prettify(client, outputter)
          desired_result = <<-STR
Target Information (where will apps be pushed):
  CF instance: http://example.com (API version: 2)
  user: N/A
  target app space: N/A (org: N/A)
          STR
          desired_result.each_line do |line|
            outputter.should have_received(:line).with(line.chomp)
          end
        end
      end
    end
  end
end