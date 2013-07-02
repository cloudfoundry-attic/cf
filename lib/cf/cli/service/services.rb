require "cf/cli/service/base"

module CF::Service
  class Services < Base
    desc "List your services"
    group :services
    input :space, :desc => "Show services in given space",
          :from_given => by_name(:space),
          :default => proc { client.current_space }
    input :name, :desc => "Filter by name"
    input :service, :desc => "Filter by service type"
    input :plan, :desc => "Filter by service plan"
    input :provider, :desc => "Filter by service provider"
    input :version, :desc => "Filter by service version"
    input :app, :desc => "Limit to application's service bindings",
          :from_given => by_name(:app)
    input :full, :desc => "Verbose output format", :default => false
    input :marketplace, :desc => "List supported services", :default => false, :alias => "-m"

    def services
      return show_marketplace if input[:marketplace]

      set_services
      return show_full if input[:full]
      return show_services_table
    end

    private

    def set_services
      @services =
        with_progress(services_msg) do
          client.service_instances(:depth => 2)
        end

      line unless quiet?

      if @services.empty? and !quiet?
        line "No services."
        return
      end

      @services.reject! do |i|
        !service_matches(i, input)
      end
    end

    def show_marketplace
      services = with_progress("Getting services") { client.services }

      line unless quiet?

      table(
        ["service", "version", "provider", "plans", "description"],
        services.sort_by(&:label).collect { |s|
          [c(s.label, :name),
            s.version,
            s.provider,
            s.service_plans.collect(&:name).join(", "),
            s.description
          ]
        })
    end

    def show_full
      spaced(@services) do |s|
        invoke :service, :service => s
      end
    end

    def show_services_table
      table(
        ["name", "service", "provider", "version", "plan", "bound apps"],
        @services.collect { |i|
          plan = i.service_plan
          service = plan.service

          label    = service.label
          version  = service.version
          apps     = name_list(i.service_bindings.collect(&:app))
          provider = service.provider

          [ c(i.name, :name),
            label,
            provider,
            version,
            plan.name,
            apps
          ]
        })

    end

    def services_msg
      if space = input[:space]
        "Getting services in #{c(space.name, :name)}"
      else
        "Getting services"
      end
    end

    def service_matches(i, options)
      if app = options[:app]
        return false unless app.services.include? i
      end

      if name = options[:name]
        return false unless File.fnmatch(name, i.name)
      end

      plan = i.service_plan

      if service = options[:service]
        return false unless File.fnmatch(service, plan.service.label)
      end

      if plan = options[:plan]
        return false unless File.fnmatch(plan.upcase, plan.name.upcase)
      end

      if provider = options[:provider]
        return false unless File.fnmatch(provider, plan.service.provider)
      end

      if version = options[:version]
        return false unless File.fnmatch(version, plan.service.version)
      end

      true
    end
  end
end
