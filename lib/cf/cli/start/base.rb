require "cf/cli"

module CF
  module Start
    class Base < CLI

      # Make sure we only show the target once
      @@displayed_target = false

      def displayed_target?
        @@displayed_target
      end

      private

      def show_context
        return if quiet? || displayed_target?

        display_target

        line

        @@displayed_target = true
      end

      def display_target
        if quiet?
          line client.target
        else
          line "target: #{c(client.target, :name)}"
        end
      end
    end
  end
end
