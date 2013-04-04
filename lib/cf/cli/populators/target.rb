require "cf/cli/populators/target_interactions"
require "cf/cli"

module CF
  module Populators
    class Target < CF::CLI
      include TargetInteractions

      attr_reader :input, :info

      def initialize(input)
        @input = input
        @info = target_info
      end

      def populate_and_save!
        organization = get_organization

        if organization
          info[:organization] = organization.guid

          if (space = get_space(organization))
            info[:space] = space.guid
          end
        end

        save_target_info(info)
        invalidate_client
      end

      private

      def get_organization
        if input.has?(:organization)
          organization = input[:organization]
          with_progress("Switching to organization #{c(organization.name, :name)}") {}
        elsif info[:organization]
          previous_organization = client.organization(info[:organization])
          organization = previous_organization if organization_valid?(previous_organization)
        end

        organization || ask_organization
      end

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

      def organization_valid?(organization)
        return false unless organization.guid
        organization.users.include? client.current_user
      rescue CFoundry::APIError
        false
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