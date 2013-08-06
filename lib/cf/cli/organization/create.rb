require "cf/cli/organization/base"

module CF::Organization
  class Create < Base
    desc "Create an organization"
    group :organizations
    input :name, :desc => "Organization name", :argument => :optional
    input :target, :desc => "Switch to the organization after creation",
          :alias => "-t", :default => true
    input :add_self, :desc => "Add yourself to the organization",
          :default => true
    input :find_if_exists, :desc => "Use an existing organization if one already exists with the given name", :default => false
    def create_org
      org = client.organization
      org.name = input[:name]
      org.users = [client.current_user] if input[:add_self]

      begin
        with_progress("Creating organization #{c(org.name, :name)}") { org.create! }
      rescue CFoundry::OrganizationNameTaken
        raise unless input[:find_if_exists]
        org = client.organization_by_name(input[:name])
      end

      if input[:target]
        invoke :target, :organization => org
      end
    end

    private

    def ask_name
      ask("Name")
    end
  end
end
