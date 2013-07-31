require "cf/cli/app/base"

module CF::App
  class Events < Base
    desc "Display application events"
    group :apps, :info
    input :app, :desc => "Application to get the events for",
          :argument => true, :from_given => by_name(:app)
    def events
      app = input[:app]

      events =
        with_progress("Getting events for #{c(app.name, :name)}") do
          format_events(app.events)
        end

      line unless quiet?
      table(%w{time instance\ index description exit\ status}, events)

    end

    private

    def sort_events(events)
      events.sort_by { |event| DateTime.parse(event.timestamp) }
    end

    def format_events(events)
      sort_events(events).map do |event|
        [event.timestamp,
         c(event.instance_index.to_s, :warning),
         event.exit_description,
         format_status(event)]
      end
    end

    def format_status(event)
      if event.exit_status == 0
        c("Success (#{event.exit_status})", :good)
      else
        c("Failure (#{event.exit_status})", :bad)
      end
    end
  end
end
