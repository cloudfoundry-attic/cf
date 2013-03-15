require "vmc/cli/route/base"

module VMC::Route
  class Unmap < Base
    desc "Remove a URL mapping"
    group :apps, :info, :hidden => true
    input :url, :desc => "URL to unmap", :argument => :optional,
          :from_given => find_by_name("route") { client.routes }
    input :app, :desc => "Application to remove the URL from",
          :argument => :optional, :from_given => by_name(:app)
    input :delete, :desc => "Delete route", :type => :boolean
    input :all, :desc => "Act on all routes", :type => :boolean
    input :really, :type => :boolean, :forget => true, :hidden => true,
          :default => proc { force? || interact }
    def unmap
      if input[:all]
        if input.has?(:app)
          app = target = input[:app]
          return unless !input[:delete] || input[:really, "ALL URLS bound to #{target.name}", :bad]
        else
          target = client
          return unless !input[:delete] || input[:really, "ALL URLS", :bad]
        end

        target.routes.each do |r|
          begin
            invoke :unmap, :delete => input[:delete], :url => r, :really => true, :app => app
          rescue CFoundry::APIError => e
            err "#{e.class}: #{e.message}"
          end
        end

        return
      end

      app = input[:app]
      url = input[:url, app ? app.routes : client.routes]

      if input[:delete]
        with_progress("Deleting route #{c(url.name, :name)}") do
          url.delete!
        end
      elsif app
        with_progress("Unbinding #{c(url.name, :name)} from #{c(app.name, :name)}") do
          app.remove_route(url)
        end
      else
        fail "Missing either --delete or --app."
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
