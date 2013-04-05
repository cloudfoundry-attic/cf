require "cf/cli"
require "cf/cli/populators/organization"

module CF
  module Space
    class Base < CLI
      def precondition
        check_target
        check_logged_in
        check_organization
      end

      def check_organization
        CF::Populators::Organization.new(input).populate_and_save!
      end

      def self.space_by_name
        proc { |name, org, *_|
          org.space_by_name(name) ||
            fail("Unknown space '#{name}'.")
        }
      end
    end
  end
end
