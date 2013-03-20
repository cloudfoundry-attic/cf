require "cf/detect"

module CF::App
  module Create
    attr_accessor :input
    attr_writer :path

    def get_inputs
      inputs = {}
      inputs[:name] = input[:name]
      inputs[:total_instances] = input[:instances]
      inputs[:space] = client.current_space if client.current_space

      inputs[:production] = !!(input[:plan] =~ /^p/i)

      inputs[:buildpack] = input[:buildpack]
      inputs[:command] = input[:command] if input.has?(:command) || !has_procfile?

      detected = detector.detected
      human_mb = human_mb((detected && detected.memory_suggestion) || 64)
      inputs[:memory] = megabytes(input[:memory, human_mb])

      inputs[:stack] = input[:stack]

      inputs
    end

    def create_app(inputs)
      app = client.app

      inputs.each { |key, value| app.send(:"#{key}=", value) }

      app = filter(:create_app, app)

      with_progress("Creating #{c(app.name, :name)}") do
        wrap_message_format_errors do
          begin
            app.create!
          rescue CFoundry::NotAuthorized
            fail "You need the Project Developer role in #{b(client.current_space.name)} to push."
          end
        end
      end

      app
    end

    def map_route(app)
      line unless quiet?

      host = input[:host, app.name]
      domain = input[:domain, app]

      mapped_url = false
      until domain == "none" || !domain || mapped_url
        begin
          host = "" if host == "none"
          invoke :map, :app => app, :host => host, :domain => domain
          mapped_url = true
        rescue CFoundry::RouteHostTaken, CFoundry::UriAlreadyTaken => e
          raise if force?

          line c(e.description, :bad)
          line

          input.forget(:host)
          input.forget(:domain)

          host = input[:host, app.name]
          domain = input[:domain, app]
        end
      end
    end

    def create_services(app)
      return unless input[:create_services]

      while true
        invoke :create_service, { :app => app }, :plan => :interact
        break unless ask("Create another service?", :default => false)
      end
    end

    def bind_services(app)
      return unless input[:bind_services]

      while true
        invoke :bind_service, :app => app
        break if (all_instances - app.services).empty?
        break unless ask("Bind another service?", :default => false)
      end
    end

    def start_app(app)
      invoke :start, :app => app if input[:start]
    end

    private

    def has_procfile?
      File.exists?("#@path/Procfile")
    end

    def all_instances
      @all_instances ||= client.service_instances
    end

    def detector
      @detector ||= CF::Detector.new(client, @path)
    end

    def target_base
      client.target.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
    end
  end
end
