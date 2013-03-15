require "cf/cli"

module CF
  module Organization
    class Base < CLI
      def precondition
        check_target
        check_logged_in
      end
    end
  end
end
