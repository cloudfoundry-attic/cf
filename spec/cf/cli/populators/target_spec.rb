require "spec_helper"

module CF
    describe Populators::Target do
      describe "#populate_and_save!" do
        let(:input) { double(:input) }
        let(:organization_populator) { double(Populators::Organization) }
        let(:space_populator) { double(Populators::Space) }

        def execute_populate_and_save
          Populators::Target.new(input).populate_and_save!
        end

        context 'when there are no orgs' do
          it 'does not try to populate the space' do
            Populators::Organization.stub(:new).and_return(organization_populator)
            organization_populator.stub(:populate_and_save!).and_return(nil)

            Populators::Space.stub(:new).and_return(space_populator)
            space_populator.should_not receive(:populate_and_save!)

            execute_populate_and_save
          end
        end

        it "uses a organization_populator then a space_populator populator" do
          Populators::Organization.should_receive(:new).with(input).and_return(organization_populator)

          cfoundry_organization = double(CFoundry::V2::Organization)
          organization_populator.should_receive(:populate_and_save!).and_return(cfoundry_organization)

          Populators::Space.should_receive(:new).with(input, cfoundry_organization).and_return(space_populator)
          space_populator.should_receive(:populate_and_save!)

          execute_populate_and_save
        end
      end
    end
end
