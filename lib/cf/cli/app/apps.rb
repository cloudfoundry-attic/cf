require "cf/cli/app/base"

module CF::App
  class Apps < Base
    desc "List your applications"
    group :apps
    input :space, :desc => "Show apps in given space",
          :default => proc { client.current_space },
          :from_given => by_name(:space)
    input :name, :desc => "Filter by name regexp"
    input :url, :desc => "Filter by url regexp"
    input :full, :desc => "Verbose output format", :default => false
    def apps
      if space = input[:space]
        begin
          space.summarize!
        rescue CFoundry::APIError
        end

        apps =
          with_progress("Getting applications in #{c(space.name, :name)}") do
            space.apps
          end
      else
        apps =
          with_progress("Getting applications") do
            client.apps(:depth => 2)
          end
      end

      line unless quiet?

      if apps.empty? and !quiet?
        line "No applications."
        return
      end

      apps.reject! do |a|
        !app_matches?(a, input)
      end

      apps = apps.sort_by(&:name)

      if input[:full]
        spaced(apps) do |a|
          invoke :app, :app => a
        end
      elsif quiet?
        apps.each do |a|
          line a.name
        end
      else
        display_apps_table(apps)
      end
    end

    def display_apps_table(apps)
      table(
        ["name", "status", "usage", "url"],
        apps.collect { |a|
          [ c(a.name, :name),
            app_status(a),
            "#{a.total_instances} x #{human_mb(a.memory)}",
            if a.urls.empty?
              d("none")
            elsif a.urls.size == 1
              a.url
            else
              "#{a.url}, ..."
            end
          ]
        })
    end

    def app_matches?(a, options)
      if name = options[:name]
        return false if a.name !~ /#{name}/
      end

      if url = options[:url]
        return false if a.urls.none? { |u| u =~ /#{url}/ }
      end

      true
    end
  end
end
