class ServiceHelper
  def initialize(service)
    @service = service
  end

  def label
    @service.label
  end

  def provider
    @service.provider || 'n/a'
  end

  def version
    @service.version || 'n/a'
  end

  def service_plans
    @service.service_plans.map(&:name).join(', ')
  end

  def description
    @service.description
  end
end
