require "cf/cli/route/base"

module CF::Route
  class Unmap < Base
    desc "Remove a URL mapping"
    group :apps, :info
    input :url, :desc => "URL to unmap", :argument => :optional,
          :from_given => find_by_name("route") { client.routes }
    input :app, :desc => "Application to remove the URL from",
          :argument => :optional, :from_given => by_name(:app)
    input :all, :desc => "Act on all routes", :type => :boolean
    input :really, :type => :boolean, :forget => true, :hidden => true,
          :default => proc { force? || interact }

    def unmap
      if input[:all]
        if input.has?(:app)
          app = target = input[:app]
        else
          target = client
        end

        target.routes.each do |r|
          begin
            invoke :unmap, :url => r, :really => true, :app => app
          rescue CFoundry::APIError => e
            err "#{e.class}: #{e.message}"
          end
        end

        return
      end

      app = input[:app]
      url = input[:url, app ? app.routes : client.routes]

      if app
        with_progress("Unbinding #{c(url.name, :name)} from #{c(app.name, :name)}") do
          app.remove_route(url)
        end
      else
        fail "Missing --app."
      end
    end

    private

    def ask_url(choices)
      ask("Which URL?", :choices => choices.sort_by(&:name), :display => proc(&:name))
    end

    def ask_really(name, color)
      ask("Really delete #{c(name, color)}?", :default => false)
    end
  end
end
