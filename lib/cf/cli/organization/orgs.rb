require "cf/cli/organization/base"

module CF::Organization
  class Orgs < Base
    desc "List available organizations"
    group :organizations
    input :full, :desc => "Show full information for apps, services, etc.",
          :default => false
    def orgs
      orgs =
        with_progress("Getting organizations") do
          client.organizations(:depth => 0).sort_by(&:name)
        end

      return if orgs.empty?

      line unless quiet?

      if input[:full]
        orgs.each do |o|
          invoke :org, :organization => o, :full => true
        end
      else
        table(
          %w{name},
          orgs.collect { |o| [c(o.name, :name)] })
      end
    end
  end
end
