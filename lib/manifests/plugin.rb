require "pathname"
require "cf/plugin"
require "manifests/manifests"

class ManifestsPlugin < CF::App::Base
  include CFManifests

  def self.default_to_app_from_manifest(command, fail_without_app)
    name_made_optional = change_argument(command, :app, :optional)
    around(command) do |cmd, input|
      wrap_with_optional_name(name_made_optional, cmd, input, fail_without_app)
    end
  end

  option :manifest, :aliases => "-m", :value => :file, :desc => "Path to manifest file to use"


  [:start, :restart, :instances, :logs, :env, :health, :stats, :scale, :app, :stop, :delete, :events].each do |command|
    ::ManifestsPlugin.default_to_app_from_manifest command, true
  end

  add_input :push, :reset, :desc => "Reset to values in the manifest", :default => false

  around(:push) do |push, input|
    wrap_push(push, input)
  end

  private

  def wrap_with_optional_name(name_made_optional, cmd, input, fail_without_app)
    return cmd.call if input[:all]

    unless manifest
      # if the command knows how to handle this
      if input.has?(:app) || !name_made_optional || !fail_without_app
        return cmd.call
      else
        return no_apps
      end
    end

    internal, external = apps_in_manifest(input)

    return cmd.call if internal.empty? && !external.empty?

    show_manifest_usage

    if internal.empty? && external.empty?
      internal = current_apps if internal.empty?
      internal = all_apps if internal.empty?
    end

    internal = internal.collect { |app| app[:name] }

    apps = internal + external
    return no_apps if fail_without_app && apps.empty?

    apps.each.with_index do |app, num|
      line unless quiet? || num == 0
      cmd.call(input.without(:apps).merge_given(:app => app))
    end
  end

  def apply_changes(app, input)
    app.memory = megabytes(input[:memory]) if input.has?(:memory)
    app.total_instances = input[:instances] if input.has?(:instances)
    app.command = input[:command] if input.has?(:command)
    app.buildpack = input[:buildpack] if input.has?(:buildpack)
  end

  def wrap_push(push, input)
    unless manifest
      create_and_save_manifest(push, input)
      return
    end

    line(c("--path is ignored when using a manifest. Please specify the path in the manifest.", :warning)) if input.has?(:path)

    particular, external = apps_in_manifest(input)

    unless external.empty?
      fail "Could not find #{b(external.join(", "))}' in the manifest."
    end

    apps = particular.empty? ? all_apps : particular

    show_manifest_usage

    spaced(apps) do |app_manifest|
      push_with_manifest(app_manifest, push, input)
    end
  end

  def push_with_manifest(app_manifest, push, input)
    with_filters(
      :push => {
        :create_app => proc { |a|
          setup_env(a, app_manifest)
          a
        },
        :push_app => proc { |a|
          setup_services(a, app_manifest)
          a
        }
      }) do
      app_input = push_input_for(app_manifest, input)

      push.call(app_input)
    end
  end

  def push_input_for(app_manifest, input)
    existing_app = client.app_by_name(app_manifest[:name])
    rebased_input = input.rebase_given(app_manifest)

    if !existing_app || input[:reset]
      input = rebased_input
    else
      warn_reset_changes if manifest_differs?(existing_app, rebased_input)
    end

    input.merge(
      :path => from_manifest(app_manifest[:path]),
      :name => app_manifest[:name],
      :bind_services => false,
      :create_services => false)
  end

  def manifest_differs?(app, input)
    apply_changes(app, input)
    app.changed?
  end

  def create_and_save_manifest(push, input)
    with_filters(
        :push => { :push_app => proc { |a| ask_to_save(input, a); a } }) do
      push.call
    end
  end
end
