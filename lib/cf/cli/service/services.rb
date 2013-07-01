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
      services =
        with_progress(services_msg) do
          client.service_instances(:depth => 2)
        end

      line unless quiet?

      if services.empty? and !quiet?
        line "No services."
        return
      end

      services.reject! do |i|
        !service_matches(i, input)
      end

      if input[:full]
        spaced(services) do |s|
          invoke :service, :service => s
        end
      else
        table(
          ["name", "service", "provider", "version", "plan", "bound apps"],
          services.collect { |i|
            plan = i.service_plan
            service = plan.service

            label = service.label
            version = service.version
            apps = name_list(i.service_bindings.collect(&:app))
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
    end

    def services_msg
      if space = input[:space]
        "Getting services in #{c(space.name, :name)}"
      else
        "Getting services"
      end
    end

    def marketplace

    end

    private

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
