require "cf/cli"

module CF
  module Populators
    class Base < CF::CLI
      attr_reader :input, :info

      def initialize(input)
        @input = input
        @info = target_info
      end
    end
  end
end