require "cf/cli/start/base"

module CF::Start
  class Colors < Base
    desc "Show color configuration"
    group :start
    def colors
      user_colors.each do |n, c|
        line "#{n}: #{c(c.to_s, n)}"
      end
    end
  end
end
