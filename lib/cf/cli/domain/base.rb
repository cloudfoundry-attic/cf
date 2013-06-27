require "cf/cli"

module CF
  module Domain
    class Base < CLI
      include LoginRequirements
    end
  end
end
