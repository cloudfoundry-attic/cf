require "cf/cli/service/base"

module CF::Service
  USER_PROVIDED_OFFERING = "user-provided" # I'd rather move this to CFoundry

  class UPDummy
    def label
      "user-provided"
    end

    attr_reader :version, :provider
  end

  class Create < Base
    offerings_from_label = proc { |label, offerings|
      offerings.select { |s| s.label == label }
    }

    desc "Create a service"
    group :services, :manage
    input :offering, :desc => "What kind of service (e.g. redis, mysql)",
      :argument => :optional, :from_given => offerings_from_label
    input :name, :desc => "Name for your service", :argument => :optional
    input :plan, :desc => "Service plan",
      :from_given => find_by_name_insensitive("plan"),
      :default => proc {
        interact
      }
    input :provider, :desc => "Service provider"
    input :version, :desc => "Service version"
    input :app, :desc => "Application to immediately bind to",
      :alias => "--bind", :from_given => by_name(:app)

    def create_service
      offerings = client.services

      if input[:provider]
        offerings.reject! { |s| s.provider != input[:provider] }
      end

      if input[:version]
        offerings.reject! { |s| s.version != input[:version] }
      end

      # filter the offerings based on a given plan value, which will be a
      # string if the user provided it with a flag, or a ServicePlan if
      # something invoked this command with a particular plan
      if plan = input.direct(:plan)
        offerings.reject! do |s|
          if plan.is_a?(String)
            s.service_plans.none? { |p| p.name.casecmp(plan) == 0 }
          else
            !s.service_plans.include? plan
          end
        end
      end
      finalize

      offerings << UPDummy.new

      selected_offerings = offerings.any? ? Array(input[:offering, offerings.sort_by(&:label)]) : []
      finalize

      if selected_offerings.empty?
        fail "Cannot find services matching the given criteria."
      end

      offering = selected_offerings.first

      if offering.label == CF::Service::USER_PROVIDED_OFFERING
        service_instance = client.user_provided_service_instance
        service_instance.name = input[:name, offering]
        finalize

        # at this point there's no way input[:credentials] can work interactively...
        service_instance.credentials = input[:credentials, nil] || ask_credentials
      else
        service_instance = client.managed_service_instance
        service_instance.name = input[:name, offering]
        finalize

        plan = input[:plan, offering.service_plans]
        finalize
        service_instance.service_plan = if plan.is_a?(String)
                                          offering.service_plans.find { |p| p.name.casecmp(plan) == 0 }
                                        else
                                          plan
                                        end
      end

      service_instance.space = client.current_space

      with_progress("Creating service #{c(service_instance.name, :name)}") do
        service_instance.create!
      end

      app = input[:app]
      finalize

      if app
        invoke :bind_service, :service => service_instance, :app => app
      end
      service_instance
    end

    private

    def ask_credentials
      credentials = {}

      while keys = ask("What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)").split(/\s*,\s*/).map(&:strip)
        if bad_key = keys.detect { |key| key !~ /^[-\w]+$/ }
          line("'#{bad_key}' is not a valid key")
        else
          break
        end
      end
      finalize
      keys.each do |key|
        value = ask(key)
        finalize
        credentials[key] = value
      end

      credentials
    end

    def ask_offering(offerings)
      [ask("What kind?", :choices => offerings.sort_by(&:label),
        :display => proc do |s|
          str = "#{c(s.label, :name)} #{s.version}"
          if s.provider != "core"
            str << ", via #{s.provider}"
          end
          str
        end,
        :complete => proc { |s| "#{s.label} #{s.version}" })]
    end

    def ask_name(offering)
      default = nil
      unless offering == CF::Service::USER_PROVIDED_OFFERING
        random = sprintf("%x", rand(1000000))
        default = "#{offering.label}-#{random}"
      end

      ask "Name?", :default => default
    end

    def ask_plan(plans)
      ask "Which plan?",
        :choices => plans.sort_by(&:name),
        :indexed => true,
        :display => proc { |p| "#{p.name}: #{p.description || 'No description'}" },
        :complete => proc(&:name)
    end
  end
end
