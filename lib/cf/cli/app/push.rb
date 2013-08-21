require "cf/cli/app/base"
require "cf/cli/app/push/sync"
require "cf/cli/app/push/create"
require "cf/cli/app/push/interactions"

module CF::App
  class Push < Base
    include Sync
    include Create

    desc "Push an application, syncing changes if it exists"
    group :apps, :manage
    input :name,      :desc => "Application name", :argument => :optional
    input :path,      :desc => "Path containing the bits", :default => "."
    input :host,      :desc => "Subdomain for the app's URL"
    input :domain,    :desc => "Domain for the app",
                      :from_given => proc { |given, app|
                        if given == "none"
                          given
                        else
                          app.space.domain_by_name(given) ||
                            fail_unknown("domain", given)
                        end
                      }
    input :memory,    :desc => "Memory limit"
    input :instances, :desc => "Number of instances to run", :type => :integer
    input :command,   :desc => "Startup command", :default => nil
    input :plan,      :desc => "Application plan"
    input :start,     :desc => "Start app after pushing?", :default => true
    input :restart,   :desc => "Restart app after updating?", :default => true
    input :buildpack, :desc => "Custom buildpack URL", :default => nil
    input :stack,     :desc => "Stack to use", :default => nil,
                      :from_given => by_name(:stack)
    input :create_services, :desc => "Interactively create services?",
          :type => :boolean, :default => proc { force? ? false : interact }
    input :bind_services, :desc => "Interactively bind services?",
          :type => :boolean, :default => proc { force? ? false : interact }
    interactions PushInteractions

    def push
      name = input[:name]
      path = File.expand_path(input[:path])
      app = client.app_by_name(name)

      if app
        sync_app(app, path)
      else
        setup_new_app(path)
      end
    end

    def setup_new_app(path)
      self.path = path
      app = create_app(get_inputs)
      map_route(app)
      create_services(app)
      bind_services(app)
      upload_app(app, path)
      start_app(app)
    end

    private

    def sync_app(app, path)
      upload_app(app, path)
      apply_changes(app)
      input[:path]
      display_changes(app)
      commit_changes(app)

      warn "\n#{c(app.name, :name)} is currently stopped, start it with 'cf start'" unless app.started?
    end

    def url_choices(name)
      client.current_space.domains.sort_by(&:name).collect do |d|
        # TODO: check availability
        "#{name}.#{d.name}"
      end
    end

    def upload_app(app, path)
      app = filter(:push_app, app)

      with_progress("Uploading #{c(app.name, :name)}") do
        app.upload(path)
      end
    rescue
      err "Upload failed. Try again with 'cf push'."
      raise
    end

    def wrap_message_format_errors
      yield
    rescue CFoundry::MessageParseError => e
      md = e.description.match /Field: ([^,]+)/
      field = md[1]

      case field
      when "buildpack"
        fail "Buildpack must be a public git repository URI."
      end
    end
  end
end
