require "cf/cli"

module CF
  module Start
    class Base < CLI
      # Make sure we only show the target once
      @@displayed_target = false

      def displayed_target?
        @@displayed_target
      end


      # These commands don't require authentication.
      def precondition;
      end

      private

      def show_context
        return if quiet? || displayed_target?

        display_target

        line

        @@displayed_target = true
      end

      def display_target
        if client.nil?
          fail "No target has been specified."
          return
        end

        if quiet?
          line client.target
        else
          line "target: #{c(client.target, :name)}"
        end
      end

      def set_organization(organization, info)
        client.current_organization = organization
        info[:organization] = organization.guid
      end

      def get_organization(input, info)
        if input.has?(:organization)
          organization = input[:organization]
          with_progress("Switching to organization #{c(organization.name, :name)}") {}
        elsif info[:organization]
          previous_organization = client.organization(info[:organization])
          organization = previous_organization if organization_valid?(previous_organization)
        end

        organization || input[:organization] #prompt
      end

      def set_space(space, info)
        client.current_space = space
        info[:space] = space.guid
      end

      def get_space(input, info, organization)
        if input.has?(:space)
          space = input[:space]
          with_progress("Switching to space #{c(space.name, :name)}") {}
        elsif info[:space]
          previous_space = client.space(info[:space])
          space = previous_space if space_valid?(previous_space)
        end

        space || input[:space, organization] #prompt
      end

      def select_org_and_space(input, info)
        organization = get_organization(input, info)

        if organization
          set_organization(organization, info)
          if space = get_space(input, info, organization)
            set_space(space, info)
          end
        end
      end

      def organization_valid?(organization, user = client.current_user)
        return false unless organization.guid
        organization.users.include? user
      rescue CFoundry::APIError
        false
      end

      def space_valid?(space, user = client.current_user)
        return false unless space.guid
        space.developers.include? user
      rescue CFoundry::APIError
        false
      end
    end
  end
end
