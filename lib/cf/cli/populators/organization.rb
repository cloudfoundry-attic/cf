require "cf/cli"
require "cf/cli/populators/target_interactions"

module CF
  module Populators
    class Organization < CF::CLI
      include TargetInteractions

      attr_reader :input, :info

      def initialize(input)
        @input = input
        @info = target_info
      end

      def populate_and_save!
        organization = get_organization
        info[:organization] = organization.guid
        save_target_info(info)
        invalidate_client

        organization
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

      def organization_valid?(organization)
        return false unless organization.guid
        organization.users.include? client.current_user
      rescue CFoundry::APIError
        false
      end
    end
  end
end
