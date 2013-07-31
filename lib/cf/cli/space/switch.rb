require "cf/cli/space/base"

module CF::Space
  class Switch < Base
    desc "Switch to a space"
    group :spaces
    input :name, :desc => "Space name", :argument => true
    def switch_space
      space = client.space_by_name(input[:name])

      if space
        invoke :target, :space => space
      else
        raise CF::UserError, "The space #{input[:name]} does not exist, please create the space first."
      end
    end
  end
end
