require "cf/cli"
require "cf/cli/populators/organization"
require "cf/cli/populators/space"

module CF
  module Populators
    class Target < CF::CLI
      attr_reader :input, :info

      def initialize(input)
        @input = input
        @info = target_info
      end

      def populate_and_save!
        organization = CF::Populators::Organization.new(input).populate_and_save!
        CF::Populators::Space.new(input, organization).populate_and_save!
      end
    end
  end
end