module CF::App
  module PushInteractions
    def ask_name
      ask("Name")
    end

    def ask_host(name)
      # Use .dup here because when we pass app.name deep into interactive,
      # it needs an unfrozen String because the cli allows people to change
      # this value.
      host = name.dup
      ask "Subdomain", :choices => [host, "none"],
        :default => host,
        :allow_other => true
    end

    def ask_domain(app)
      choices = app.space.domains

      options = {
        :choices => choices + ["none"],
        :display => proc { |choice| choice.is_a?(String) ? choice : choice.name },
        :allow_other => true
      }

      options[:default] = choices.first

      ask "Domain", options
    end

    def ask_memory(default)
      ask("Memory Limit",
          :choices => memory_choices,
          :allow_other => true,
          :default => default || "128M")
    end

    def ask_instances
      ask("Instances", :default => 1)
    end

    def ask_command
      command = ask("Custom startup command", :default => "none")

      if command != "none"
        command
      end
    end

    def ask_create_services
      line unless quiet?
      ask "Create services for application?", :default => false
    end

    def ask_bind_services
      return if all_instances.empty?

      ask "Bind other services to application?", :default => false
    end

    private

    def ask_with_other(message, all, choices, default, other)
      choices = choices.sort_by(&:name)
      choices << other if other

      opts = {
        :choices => choices,
        :display => proc { |x|
          if other && x == other
            "other"
          else
            x.name
          end
        }
      }

      opts[:default] = default if default

      res = ask(message, opts)

      if other && res == other
        opts[:choices] = all
        res = ask(message, opts)
      end

      res
    end
  end
end
