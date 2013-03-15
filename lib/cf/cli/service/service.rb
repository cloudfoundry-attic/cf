require "cf/cli/service/base"

module CF::Service
  class Service < Base
    desc "Show service information"
    group :services
    input :service, :desc => "Service to show", :argument => :required,
          :from_given => by_name(:service_instance, :service)
    def service
      display_service(input[:service])
    end

    private

    def display_service(i)
      if quiet?
        line i.name
      else
        plan = i.service_plan
        service = plan.service

        apps = i.service_bindings.collect { |b|
          c(b.app.name, :name)
        }.join(", ")

        line "#{c(i.name, :name)}: #{service.label} #{service.version}"

        indented do
          line "provider: #{c(service.provider, :name)}"
          line "bound to: #{apps}" unless apps.empty?
          line "plan: #{c(plan.name, :name)}"

          indented do
            line "description: #{plan.description}"
          end
        end
      end
    end
  end
end
