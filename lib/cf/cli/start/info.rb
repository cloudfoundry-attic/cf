require "cf/cli/start/base"

module CF::Start
  class Info < Base
    def precondition
      check_target
    end

    desc "Display information on the current target, user, etc."
    group :start
    input :services, :desc => "List supported services", :alias => "-s",
          :default => false
    input :all, :desc => "Show all information", :alias => "-a",
          :default => false
    def info
      all = input[:all]

      if all || input[:services]
        services = with_progress("Getting services") { client.services }
      end

      if all || !services
        info = client.info

        line if services
        line info[:description]
        line
        line "target: #{b(client.target)}"

        indented do
          line "version: #{info[:version]}"
          line "support: #{info[:support]}"
        end

        if (user = client.current_user)
          line
          line "user: #{b(user.email || user.guid)}"
        end
      end

      if services
        line unless quiet?

        if services.empty? && !quiet?
          line "#{d("none")}"
        elsif input[:quiet]
          services.each do |s|
            line s.label
          end
        else
          table(
              ["service", "version", "provider", "plans", "description"],
              services.sort_by(&:label).collect { |s|
                [c(s.label, :name),
                 s.version,
                 s.provider,
                 s.service_plans.collect(&:name).join(", "),
                 s.description
                ]
              })
        end
      end
    end
  end
end
