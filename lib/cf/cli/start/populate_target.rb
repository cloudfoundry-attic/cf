require "cf/cli/start/target_interactions"
require "cf/cli"

module CF::Start
  class PopulateTarget < CF::CLI
    include TargetInteractions

    attr_reader :input, :info, :client

    def initialize(input, client)
      @input = input
      @info = target_info
      @client = client
    end

    def populate_and_save!
      organization = get_organization(input, info)

      if organization
        set_organization(organization, info)
        if space = get_space(input, info, organization)
          set_space(space, info)
        end
      end

      save_target_info(info)
    end

    private

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

      organization || ask_organization
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

      space || ask_space(organization)
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