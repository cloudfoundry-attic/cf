module CF
  module Populators
    module TargetInteractions
      def ask_organization
        organization_choices = client.organizations(:depth => 0)

        if organization_choices.empty?
          raise CF::UserFriendlyError.new(
            "There are no organizations. You may want to create one with #{c("create-org", :good)}."
          )
        elsif organization_choices.size == 1 && !input.interactive?(:organization)
          organization_choices.first
        else
          ask("Organization",
            :choices => organization_choices.sort_by(&:name),
            :display => proc(&:name))
        end
      end

      def ask_space(org)
        space_choices = org.spaces(:depth => 0)

        if space_choices.empty?
          raise CF::UserFriendlyError.new(
            "There are no spaces. You may want to create one with #{c("create-space", :good)}."
          )
        elsif space_choices.size == 1 && !input.interactive?(:spaces)
          space_choices.first
        else
          ask("Space", :choices => space_choices, :display => proc(&:name))
        end
      end
    end
  end
end
