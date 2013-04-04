require "cf/cli"
require "cf/cli/populators/target_interactions"

module CF
  module Populators
    class Space < CF::CLI
      include TargetInteractions

      attr_reader :input, :info, :organization

      def initialize(input, organization)
        @input = input
        @info = target_info
        @organization = organization
      end

      def populate_and_save!
        space = get_space(organization)
        info[:space] = space.guid
        save_target_info(info)
        invalidate_client

        space
      end

      private

      def get_space(organization)
        if input.has?(:space)
          space = input[:space]
          with_progress("Switching to space #{c(space.name, :name)}") {}
        elsif info[:space]
          previous_space = client.space(info[:space])
          space = previous_space if space_valid?(previous_space)
        end

        space || ask_space(organization)
      end

      def space_valid?(space)
        return false unless space.guid
        space.developers.include? client.current_user
      rescue CFoundry::APIError
        false
      end
    end
  end
end