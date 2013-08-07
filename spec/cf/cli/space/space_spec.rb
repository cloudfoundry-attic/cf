require "spec_helper"

module CF
  module Space
    describe Space do
      describe "metadata" do
        let(:command) { Mothership.commands[:space] }

        describe "command" do
          subject { command }
          its(:description) { should eq "Show space information" }
          it { expect(Mothership::Help.group(:spaces)).to include(subject) }
        end

        include_examples "inputs must have descriptions"

        describe "arguments" do
          subject { command.arguments }
          it "has the correct argument order" do
            should eq([
              {:type => :optional, :value => nil, :name => :space}
            ])
          end
        end
      end

      describe "running the command" do
        let(:client) { build(:client) }

        let(:apps) { Array.new(2) { build(:app) } }
        let(:domains) { Array.new(2) { build(:domain) } }
        let(:services) { Array.new(2) { build(:managed_service_instance) } }
        let(:space) { build(:space, :name => "some_space_name", :apps => apps, :service_instances => services, :domains => domains, :organization => organization ) }
        let(:spaces) { [space] }
        let(:organization) { build(:organization, :name => "Spacey Org") }

        before do
          stub_client_and_precondition
          CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
          CF::Populators::Space.any_instance.stub(:populate_and_save!).and_return(space)
        end

        context "with --quiet" do
          subject { cf %W[space some_space_name --quiet] }

          it "shows only the name" do
            subject
            expect(stdout.read).to eq("some_space_name\n")
          end
        end

        context "with --no-quiet" do
          subject { cf %W[space some_space_name --no-quiet] }

          before { subject }

          it "shows the space's name" do
            expect(stdout.read).to include("some_space_name:")
          end

          it "shows the space's org" do
            expect(stdout.read).to include("organization: Spacey Org")
          end

          it "shows apps" do
            expect(stdout.read).to include("apps: #{apps.first.name}, #{apps.last.name}")
          end

          it "shows services" do
            expect(stdout.read).to include("services: #{services.first.name}, #{services.last.name}")
          end

          it "shows domains" do
            expect(stdout.read).to include("domains: #{domains.first.name}, #{domains.last.name}")
          end
        end
      end
    end
  end
end
