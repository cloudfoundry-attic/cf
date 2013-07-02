require "cf/cli/start/base"
require "cf/cli/populators/target"

module CF::Start
  class Target < Base
    desc "Set or display the target cloud, organization, and space"
    group :start
    input :url, :desc => "Target URL to switch to", :argument => :optional
    input :organization, :desc => "Organization" , :aliases => %w{--org -o},
          :from_given => by_name(:organization)
    input :space, :desc => "Space", :alias => "-s",
          :from_given => by_name(:space)

    def target
      unless input.has?(:url) || input.has?(:organization) || \
              input.has?(:space)
        display_target
        display_org_and_space unless quiet?
        return
      end

      set_target_url if input.has?(:url)
     
      return unless client.logged_in?

      if input.has?(:organization) || input.has?(:space)
        CF::Populators::Target.new(input).populate_and_save!
      end

      return if quiet?

      invalidate_client

      line
      display_target
      display_org_and_space
    end

    private
    
    def set_target_url
      target = sane_target_url(input[:url])
      with_progress("Setting target to #{c(target, :name)}") do
        begin
          CFoundry::Client.new(target) # check that it's valid before setting
        rescue CFoundry::TargetRefused
          fail "Target refused connection."
        rescue CFoundry::InvalidTarget
          fail "Invalid target URI."
        end

        set_target(target)
      end
    end

    def display_org_and_space
      if (org = client.current_organization)
        line "organization: #{c(org.name, :name)}"
      end

      if (space = client.current_space)
        line "space: #{c(space.name, :name)}"
      end
    rescue CFoundry::APIError
    end
  end
end
