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
      unless input.has?(:url) || input.has?(:organization) || input.has?(:space)
        TargetPrettifier.prettify(client, self)
        return
      end

      if input.has?(:url)
        target = sane_target_url(input[:url])
        with_progress("Setting target to #{c(target, :name)}") do
          begin
            build_client(target).info # check that it's valid before setting
          rescue CFoundry::TargetRefused
            fail "Target refused connection."
          rescue CFoundry::InvalidTarget
            fail "Invalid target URI."
          end

          set_target(target)
        end
      end

      return unless client.logged_in?
      if input.has?(:organization) || input.has?(:space)
        CF::Populators::Target.new(input).populate_and_save!
      end

      return if quiet?

      invalidate_client

      line
      TargetPrettifier.prettify(client, self)
    end

    public :c
  end
end
