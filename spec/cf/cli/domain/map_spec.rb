require "spec_helper"

module CF
  module Domain
    describe Map do
      before do
        stub_client_and_precondition
      end

      let(:client) do
        build(:client).tap do |client|
          client.stub(
            :current_organization => organization,
            :current_space => space,
            :spaces => [space],
            :organizations => [organization],
            :domains => domains)
        end
      end
      let(:organization) { build(:organization) }
      let(:space) { build(:space, :organization => organization) }
      let(:domain) { build(:domain, :name => domain_name) }
      let(:domain_name) { "some.domain.com" }
      let(:domains) { [domain] }

      shared_examples_for "binding a domain to a space" do
        it "adds the domain to the space's organization" do
          space.organization.should_receive(:add_domain).with(domain)
          space.stub(:add_domain)
          subject
        end

        it "adds the domain to the space" do
          space.organization.stub(:add_domain)
          space.should_receive(:add_domain).with(domain)
          subject
        end
      end

      shared_examples_for "binding a domain to an organization" do
        it "does NOT add the domain to a space" do
          space.class.any_instance.should_not_receive(:add_domain).with(domain)
        end

        it "adds the domain to the organization" do
          organization.should_receive(:add_domain).with(domain)
          subject
        end
      end

      shared_examples_for "mapping a domain to a space" do
        context "when the domain does NOT exist" do
          let(:domains) { [] }

          before do
            client.stub(:domain) { domain }
            domain.stub(:create!)
          end

          it "creates the domain" do
            space.organization.stub(:add_domain)
            space.should_receive(:add_domain).with(domain)

            domain.should_receive(:create!)
            subject
            expect(domain.name).to eq domain_name
            expect(domain.owning_organization).to eq organization
          end

          include_examples "binding a domain to a space"
        end

        context "when the domain already exists" do
          include_examples "binding a domain to a space"
        end
      end

      context "when a domain and a space are passed" do
        subject { cf %W[map-domain #{domain.name} --space #{space.name}] }
        before { organization.stub(:spaces).and_return([space]) }

        include_examples "mapping a domain to a space"
      end

      context "when a domain and an organization are passed" do
        subject { cf %W[map-domain #{domain.name} --organization #{organization.name}] }

        context "and the domain does NOT exist" do
          let(:domains) { [] }

          before do
            client.stub(:domain) { domain }
            domain.stub(:create!)
            organization.stub(:add_domain)
          end

          include_examples "binding a domain to an organization"

          it "creates the domain" do
            domain.should_receive(:create!)
            subject
            expect(domain.name).to eq domain_name
          end

          context "and the --shared option is passed" do
            subject { cf %W[map-domain #{domain.name} --organization #{organization.name} --shared] }

            it "adds the domain to the organization" do
              organization.should_receive(:add_domain).with(domain)
              subject
            end

            it "does not add the domain to a specific organization" do
              domain.stub(:create!)
              subject
              expect(domain.owning_organization).to be_nil
            end
          end
        end

        context "and the domain already exists" do
          include_examples "binding a domain to an organization"
        end
      end

      context "when a domain, organization, and space is passed" do
        subject { cf %W[map-domain #{domain.name} --space #{space.name} --organization #{organization.name}] }
        before { organization.stub(:spaces).and_return([space]) }

        include_examples "mapping a domain to a space"
      end

      context "when only a domain is passed" do
        subject { cf %W[map-domain #{domain.name}] }

        include_examples "mapping a domain to a space"
      end
    end
  end
end
