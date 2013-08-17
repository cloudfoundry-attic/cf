require "yaml"
require "set"
require "cf/cli/service/create"

require "manifests/loader"

module CFManifests
  MANIFEST_FILE = "manifest.yml"

  @@showed_manifest_usage = false
  @@manifest = nil

  def manifest
    return @@manifest if @@manifest

    if manifest_file && File.exists?(manifest_file)
      @@manifest = load_manifest(manifest_file)
    end
  end

  def save_manifest(save_to = manifest_file)
    fail "No manifest to save!" unless @@manifest

    File.open(save_to, "w") do |io|
      YAML.dump(@@manifest, io)
    end
  end

  # find the manifest file to work with
  def manifest_file
    return @manifest_file if @manifest_file

    unless path = input[:manifest]
      where = Dir.pwd
      while true
        if File.exists?(File.join(where, MANIFEST_FILE))
          path = File.join(where, MANIFEST_FILE)
          break
        elsif File.basename(where) == "/"
          path = nil
          break
        else
          where = File.expand_path("../", where)
        end
      end
    end

    return unless path

    @manifest_file = File.expand_path(path)
  end

  # load and resolve a given manifest file
  def load_manifest(file)
    check_manifest! Loader.new(file, self).manifest
  end

  def check_manifest!(manifest_hash, output = $stdout)
    manifest_hash[:applications].each{ |app| check_attributes!(app, output) }
    manifest_hash
  end

  def check_attributes!(app, output = $stdout)
    app.each do |k, v|
      output.puts error_message_for_attribute(k) unless known_manifest_attributes.include? k
    end
  end

  def error_message_for_attribute(attribute)
    "\e[31mWarning: #{attribute} is not a valid manifest attribute. Please " +
    "remove this attribute from your manifest to get rid of this warning\e[0m"
  end

  def known_manifest_attributes
    [:applications, :buildpack, :command, :disk, :domain, :env,
     :host, :inherit, :instances, :mem, :memory, :name,
     :path, :properties, :runtime, :services, :stack]
  end

  # dynamic symbol resolution
  def resolve_symbol(sym)
    case sym
    when "target-url"
      client_target

    when "target-base"
      target_base

    when "random-word"
      sprintf("%04x", rand(0x0100000))

    when /^ask (.+)/
      ask($1)
    end
  end

  # find apps by an identifier, which may be either a tag, a name, or a path
  def find_apps(identifier)
    return [] unless manifest

    apps = apps_by(:name, identifier)

    if apps.empty?
      apps = apps_by(:path, from_manifest(identifier))
    end

    apps
  end

  # return all the apps described by the manifest
  def all_apps
    manifest[:applications]
  end

  def current_apps
    manifest[:applications].select do |app|
      next unless app[:path]
      from_manifest(app[:path]) == Dir.pwd
    end
  end

  # splits the user's input, resolving paths with the manifest,
  # into internal/external apps
  #
  # internal apps are returned as their data in the manifest
  #
  # external apps are the strings that the user gave, to be
  # passed along wholesale to the wrapped command
  def apps_in_manifest(input = nil, use_name = true, &blk)
    names_or_paths =
      if input.has?(:apps)
        # names may be given but be [], which will still cause
        # interaction, so use #direct instead of #[] here
        input.direct(:apps)
      elsif input.has?(:app)
        [input.direct(:app)]
      elsif input.has?(:name)
        [input.direct(:name)]
      else
        []
      end

    internal = []
    external = []

    names_or_paths.each do |x|
      if x.is_a?(String)
        if x =~ %r([/\\])
          apps = find_apps(File.expand_path(x))

          if apps.empty?
            fail("Path #{b(x)} is not present in manifest #{b(relative_manifest_file)}.")
          end
        else
          apps = find_apps(x)
        end

        if !apps.empty?
          internal += apps
        else
          external << x
        end
      else
        external << x
      end
    end

    [internal, external]
  end

  def create_manifest_for(app, path)
    meta = {
      "name" => app.name,
      "memory" => human_size(app.memory * 1024 * 1024, 0),
      "instances" => app.total_instances,
      "host" => app.host || "none",
      "domain" => app.domain ? app.domain : "none",
      "path" => path
    }

    services = app.services

    unless services.empty?
      meta["services"] = {}

      services.each do |service_instance|
        if service_instance.is_a?(CFoundry::V2::UserProvidedServiceInstance)
          meta["services"][service_instance.name] = {
            "label" => "user-provided",
            "credentials" => service_instance.credentials.stringify_keys,
          }
        else
          service_plan = service_instance.service_plan
          service = service_plan.service

          meta["services"][service_instance.name] = {
            "label" => service.label,
            "provider" => service.provider,
            "version" => service.version,
            "plan" => service_plan.name
          }
        end
      end
    end

    if cmd = app.command
      meta["command"] = cmd
    end

    if buildpack = app.buildpack
      meta["buildpack"] = buildpack
    end

    meta
  end

  private

  def relative_manifest_file
    Pathname.new(manifest_file).relative_path_from(Pathname.pwd)
  end

  def show_manifest_usage
    return if @@showed_manifest_usage

    path = relative_manifest_file
    line "Using manifest file #{c(path, :name)}"
    line

    @@showed_manifest_usage = true
  end

  def no_apps
    fail "No applications or manifest to operate on."
  end

  def warn_reset_changes
    line c("Not applying manifest changes without --reset", :warning)
    line
  end

  def apps_by(attr, val)
    manifest[:applications].select do |info|
      info[attr] == val
    end
  end

  # expand a path relative to the manifest file's directory
  def from_manifest(path)
    File.expand_path(path, File.dirname(manifest_file))
  end


  def ask_to_save(input, app)
    return if manifest_file
    return unless ask("Save configuration?", :default => false)

    manifest = create_manifest_for(app, input[:path])

    with_progress("Saving to #{c("manifest.yml", :name)}") do
      File.open("manifest.yml", "w") do |io|
        YAML.dump(
          { "applications" => [manifest] },
          io)
      end
    end
  end

  def env_hash(val)
    if val.is_a?(Hash)
      val
    else
      hash = {}

      val.each do |pair|
        name, val = pair.split("=", 2)
        hash[name] = val
      end

      hash
    end
  end

  def setup_env(app, info)
    return unless info[:env]
    app.env = env_hash(info[:env])
  end

  def setup_services(app, info)
    return if !info[:services] || info[:services].empty?

    offerings = client.services

    to_bind = []

    info[:services].each do |name, svc|
      name = name.to_s

      if instance = client.service_instance_by_name(name)
        to_bind << instance
      else
        if svc[:label] == "user-provided"
          invoke :create_service,
            name: name,
            offering: CF::Service::UPDummy.new,
            app: app,
            credentials: svc[:credentials]
        else
          offering = offerings.find { |o|
            o.label == (svc[:label] || svc[:type] || svc[:vendor]) &&
              (!svc[:version] || o.version == svc[:version]) &&
              (o.provider == (svc[:provider] || "core"))
          }

          fail "Unknown service offering: #{svc.inspect}." unless offering

          plan = offering.service_plans.find { |p|
            p.name == (svc[:plan] || "D100")
          }

          fail "Unknown service plan: #{svc[:plan]}." unless plan

          invoke :create_service,
            :name => name,
            :offering => offering,
            :plan => plan,
            :app => app
        end
      end
    end

    to_bind.each do |s|
      next if app.binds?(s)

      # TODO: splat
      invoke :bind_service, :app => app, :service => s
    end
  end

  def target_base
    client_target.sub(/^[^\.]+\./, "")
  end
end
