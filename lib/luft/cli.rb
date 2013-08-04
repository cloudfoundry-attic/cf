require "luft"
require "luft/helpers"
require "luft/command"
require "heroku-api"
require "rest_client"


class Luft::CLI

  extend Luft::Helpers

  def self.start(*args)
    begin
      if $stdin.isatty
        $stdin.sync = true
      end
      if $stdout.isatty
        $stdout.sync = true
      end
      command = args.shift.strip rescue "help"
      Luft::Command.load
      Luft::Command.run(command, args)
    rescue Interrupt
      `stty icanon echo`
      error("Command cancelled.")
    rescue => error
      styled_error(error)
      exit(1)
    end
  end

end
