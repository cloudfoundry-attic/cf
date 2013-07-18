require "cf/plugin"
require "console/console"

module CFConsolePlugin
  class Console < CF::CLI
    desc "Open a console connected to your app"
    group :apps, :manage
    input :app, :argument => :required, :from_given => by_name("app"),
      :desc => "App to connect to"
    input :port, :default => 10000
    def console
      app = input[:app]

      console = CFConsole.new(client, app)
      port = console.pick_port!(input[:port])

      with_progress("Opening console on port #{c(port, :name)}") do
        console.open!
        console.wait_for_start
      end

      console.start_console
    end

    ::ManifestsPlugin.default_to_app_from_manifest :console, true

    filter(:start, :start_app) do |app|
      app.console = true
      app
    end
  end
end
