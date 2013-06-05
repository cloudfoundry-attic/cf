require "spec_helper"

module CF
  module Domain
    describe Unmap do
      before do
        stub_client_and_precondition
      end

      let(:client) do
        build(:client).tap do |client|
          client.stub(
            :current_space => space,
            :spaces => [space],
            :organizations => [organization],
            :domains => [domain])
        end
      end
      let(:organization) { build(:organization) }
      let(:space) { build(:space, :organization => organization) }
      let(:domain) { build(:domain, :name => "some.domain.com") }

      context "when the --delete flag is given" do
        subject { cf %W[unmap-domain #{domain.name} --delete] }

        it "asks for a confirmation" do
          should_ask("Really delete #{domain.name}?", :default => false) { false }
          domain.stub(:delete!)
          subject
        end

        context "and the user answers 'no' to the confirmation" do
          it "does NOT delete the domain" do
            stub_ask("Really delete #{domain.name}?", anything) { false }
            domain.should_not_receive(:delete!)
            subject
          end
        end

        context "and the user answers 'yes' to the confirmation" do
          it "deletes the domain" do
            stub_ask("Really delete #{domain.name}?", anything) { true }
            domain.should_receive(:delete!)
            subject
          end
        end
      end

      context "when a space is given" do
        subject { cf %W[unmap-domain #{domain.name} --space #{space.name}] }

        it "unmaps the domain from the space" do
          space.should_receive(:remove_domain).with(domain)
          subject
        end
      end

      context "when an organization is given" do
        subject { cf %W[unmap-domain #{domain.name} --organization #{organization.name}] }

        it "unmaps the domain from the organization" do
          organization.should_receive(:remove_domain).with(domain)
          subject
        end
      end

      context "when only the domain is given" do
        subject { cf %W[unmap-domain #{domain.name}] }

        it "unmaps the domain from the current space" do
          client.current_space.should_receive(:remove_domain).with(domain)
          subject
        end
      end
    end
  end
end
