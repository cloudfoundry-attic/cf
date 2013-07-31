require "cf/cli/app/base"

module CF::App
  class Health < Base
    desc "Get application health"
    group :apps, :info
    input :apps, :desc => "Show the health information for one or more applications", :argument => :splat,
          :singular => :app, :from_given => by_name(:app)
    def health
      apps = input[:apps]
      fail "No applications given." if apps.empty?

      health =
        with_progress("Getting health status") do
          apps.collect { |a| [a, app_status(a)] }
        end

      line unless quiet?

      spaced(health) do |app, status|
        start_line "#{c(app.name, :name)}: " unless quiet?
        puts status
      end
    end
  end
end
