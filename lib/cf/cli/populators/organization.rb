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
        organization_response = client.organizations_first_page(:depth => 0)
        if organization_response[:next_page]
          "Login successful. Too many organizations (>50) to list. Remember to set your target organization using 'target -o [ORGANIZATION]'."
        else
          organization_response[:results]
        end
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
