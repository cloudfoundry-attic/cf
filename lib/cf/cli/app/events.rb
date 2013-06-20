require "cf/cli/app/base"

module CF::App
  class Events < Base
    desc "Display application events"
    group :apps, :info, :hidden => true
    input :app, :desc => "Application to get the events for",
          :argument => true, :from_given => by_name(:app)
    def events
      app = input[:app]

      events =
        with_progress("Getting events for #{c(app.name, :name)}") do
          format_events(app.events)
        end

      line unless quiet?

      table(
        %w{time instance\ index description exit\ status},
        events
        )
    end

    private

    def format_events(events)
      events.map do |e|
        e = e[1]
        [e[:timestamp],
         e[:instance_index].to_s,
         e[:exit_description],
         (e[:exit_status] ? "Failure (" : "Success (") + e[:exit_status].to_s + ")"]
      end
    end

  end
end
