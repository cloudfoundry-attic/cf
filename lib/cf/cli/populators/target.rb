require "cf/cli/populators/organization"
require "cf/cli/populators/space"

module CF
  module Populators
    class Target < Base
      def populate_and_save!
        organization = CF::Populators::Organization.new(input).populate_and_save!

        CF::Populators::Space.new(input, organization).populate_and_save! unless organization.nil?
      end
    end
  end
end
