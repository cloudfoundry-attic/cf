module CF::Start
  module TargetInteractions
    def ask_organization
      organization_choices = client.organizations(:depth => 0)

      if organization_choices.empty?
        unless quiet?
          line
          line c("There are no organizations.", :warning)
          line "You may want to create one with #{c("create-org", :good)}."
        end
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
        unless quiet?
          line
          line c("There are no spaces in #{b(org.name)}.", :warning)
          line "You may want to create one with #{c("create-space", :good)}."
        end
      elsif space_choices.size == 1 && !input.interactive?(:spaces)
        space_choices.first
      else
        ask("Space", :choices => space_choices, :display => proc(&:name))
      end
    end
  end
end
