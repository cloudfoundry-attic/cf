class ServiceInstanceHelper
  def self.new(instance)
    "#{instance.class.name.demodulize}Helper".constantize.new(instance)
  end
end

class UserProvidedServiceInstanceHelper
  def initialize(instance)
    @instance = instance
  end

  def service_label
    "user-provided"
  end

  def service_provider
    "n/a"
  end

  def version
    "n/a"
  end

  def plan_name
    "n/a"
  end

  def matches(opts = {})
    label = opts[:service]
    if label
      return label == service_label
    end

    true
  end

  def name
    @instance.name
  end

  def service_bindings
    @instance.service_bindings
  end
end

class ManagedServiceInstanceHelper
  def initialize(service_instance)
    @instance = service_instance
    @service_helper = ServiceHelper.new(service_instance.service_plan.service)
  end

  def service_label
    @service_helper.label
  end

  def service_provider
    @service_helper.provider
  end

  def version
    @service_helper.version
  end

  def plan_name
    @instance.service_plan.name
  end

  def service_bindings
    @instance.service_bindings
  end

  def name
    @instance.name
  end

  def matches(opts = {})
    service = opts[:service]
    plan = opts[:plan]
    provider = opts[:provider]
    version = opts[:version]

    if service
      return false unless File.fnmatch(service, service_label)
    end

    if plan
      return false unless File.fnmatch(plan.upcase, plan_name.upcase)
    end

    if provider
      return false unless File.fnmatch(provider, service_provider)
    end

    if version
      return false unless File.fnmatch(version, self.version)
    end

    true
  end
end
