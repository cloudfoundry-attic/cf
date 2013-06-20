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
            # app.events
        end

      line unless quiet?

      table(
        %w{time instance\ index description exit\ status}, []
        # stats.sort_by { |idx, _| idx.to_i }.collect { |idx, info|
          # idx = c("\##{idx}", :instance)

          # if info[:state] == "DOWN"
            # [idx, c("down", :bad)]
          # else
            # stats = info[:stats]
            # usage = stats[:usage]

            # if usage
              # [ idx,
                # "#{percentage(usage[:cpu])}",
                # "#{usage(usage[:mem], stats[:mem_quota])}",
                # "#{usage(usage[:disk], stats[:disk_quota])}"
              # ]
            # else
              # [idx, c("n/a", :neutral)]
            # end
          # end
        # }
        )
    end

    # def percentage(num, low = 50, mid = 70)
      # color =
        # if num <= low
          # :good
        # elsif num <= mid
          # :warning
        # else
          # :bad
        # end

      # c(format("%.1f\%", num), color)
    # end

    # def usage(used, limit)
      # "#{b(human_size(used))} of #{b(human_size(limit, 0))}"
    # end
  end
end
