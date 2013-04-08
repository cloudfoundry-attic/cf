require "cf/cli"
require "cf/cli/populators/organization"

module CF
  module Space
    class Base < CLI
      attr_reader :org

      def precondition
        check_target
        check_logged_in
      end

      def run(name)
        @org = CF::Populators::Organization.new(input).populate_and_save!
        super(name)
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
