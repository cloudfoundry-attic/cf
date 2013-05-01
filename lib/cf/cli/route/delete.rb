require "cf/cli/route/base"

module CF::Route
  class Delete < Base
    desc "Delete a route"
    group :routes
    input :route, :desc => "Route to unmap", :argument => true,
      :from_given => find_by_name("route") { client.routes }
    input :really, :type => :boolean, :forget => true, :hidden => true,
      :default => proc { force? || interact }

    def delete_route
      route = input[:route, client.routes]

      return unless input[:really, route]

      with_progress("Deleting route #{c(route.name, :name)}") do
        route.delete!
      end
    end

    private

    def ask_really(route)
      ask("Really delete #{c(route.name, :name)}?", :default => false)
    end
  end
end
