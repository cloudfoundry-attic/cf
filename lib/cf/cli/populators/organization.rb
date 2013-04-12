require "cf/cli/populators/base"
require "cf/cli/populators/populator_methods"

module CF
  module Populators
    class Organization < Base
      include PopulatorMethods

      def changed
        info[:space] = nil
      end

      private

      def choices
        client.organizations(:depth => 0)
      end

      def valid?(organization)
        return false unless organization.guid
        organization.users.include? client.current_user
      rescue CFoundry::APIError
        false
      end
    end
  end
end
