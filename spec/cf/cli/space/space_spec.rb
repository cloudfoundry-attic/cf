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
        let(:apps) { fake_list(:app, 2) }
        let(:domains) { fake_list(:domain, 2) }
        let(:services) { fake_list(:service_instance, 2) }
        let!(:space_1) { fake(:space, :name => "some_space_name", :apps => apps, :service_instances => services, :domains => domains) }
        let(:spaces) { [space_1] }
        let(:organization) { fake(:organization, :name => "Spacey Org", :spaces => spaces) }
        let(:client) { fake_client(:spaces => spaces, :current_organization => organization) }

        before do
          CF::Space::Base.any_instance.stub(:client) { client }
          CF::Space::Base.any_instance.stub(:precondition)
          CF::Populators::Organization.any_instance.stub(:populate_and_save!).and_return(organization)
          CF::Populators::Space.any_instance.stub(:populate_and_save!).and_return(space_1)
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
