require "cf/cli/populators/base"
require "cf/cli/populators/populator_methods"

module CF
  module Populators
    class Space < Base
      attr_reader :organization
      include PopulatorMethods

      def initialize(input, organization)
        super(input)
        @organization = organization
      end

      private

      def valid?(space)
        return false unless space.guid
        space.developers.include? client.current_user
      rescue CFoundry::APIError
        false
      end

      def choices
        organization.spaces(:depth => 0)
      end

      def finder_argument
        organization
      end
    end
  end
end
