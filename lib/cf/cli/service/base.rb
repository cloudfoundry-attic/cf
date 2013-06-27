require "cf/cli"

module CF
  module Service
    class Base < CLI
      include LoginRequirements
    end
  end
end
