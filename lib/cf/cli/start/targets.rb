require "cf/cli/start/base"

module CF::Start
  class Targets < Base
    desc "List known targets."
    group :start
    def targets
      targets_info.each do |target, _|
        line target
        # TODO: print org/space
      end
    end
  end
end


