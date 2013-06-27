require "cf/cli"

module CF
  module Route
    class Base < CLI
      include LoginRequirements
    end
  end
end
