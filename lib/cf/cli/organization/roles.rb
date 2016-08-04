require "cf/cli/organization/base"

module CF
  module Organization
    class Roles < Base
      desc "Manage the roles of an organization"
      group :organizations
      input :organization, :desc => "Organization to manage",
        :argument => :optional, :aliases => ["--org", "-o"],
        :from_given => by_name(:organization),
        :default => proc { client.current_organization }
      input :role, :desc => "Target role: users, managers, billing_managers, auditors",
        :argument => :optional, :aliases => ["-r"]
      input :action, :desc => "Action to take: list, add, remove",
        :argument => :optional, :aliases => ["-a"]
      input :email, :desc => "User's email address",
        :argument => :optional, :aliases => ["-e"]
      input :recursive, :desc => "Delete recursively",
            :default => false, :forget => true
      input :really, :type => :boolean, :forget => true, :hidden => true,
            :default => proc { force? || interact }
        
      def org_roles
        action = input[:action]
        role = input[:role]
        org = input[:organization]
        
        unless org
          return if quiet?
          fail "No current organization."
        end

        if quiet?
          puts org.name
          return
        end

        case action
          when "list"
            action_list(role, org)
          when "add"
            action_add(role, org)
          when "remove"
            action_remove(role, org)
        end
      end

      def action_choices
        ["list", "add", "remove"]
      end
      
      def role_choices
        ["users", "managers", "auditors", "billing_managers"]
      end

      def action_list(role, org)

        users = 
          with_progress("Getting #{c(role, :name)} for organization: #{c(org.name, :name)}" ) do
            case role
              when "users"
                org.users(:depth => 0)
              when "managers"
                org.managers(:depth => 0)
              when "auditors"
                org.auditors(:depth => 0)
              when "billing_managers"
                org.billing_managers(:depth => 0)
            end
          end
          spaced(users) do |u|
            display_user(u)
          end

      end

      def action_add(role, org)
        email = input[:email]
        user = get_user_guid(email)
        
        if user == "Not found"
          line "User not found!"
        else
          case role
            when "users"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}") do
                org.add_user(user)
              end
            when "managers"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}") do
                org.add_manager(user)
              end
            when "auditors"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}") do
                org.add_auditor(user)
              end
            when "billing_managers"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}") do
                org.add_billing_manager(user)
              end
          end
        end
      end

      def action_remove(role, org)
        email = input[:email]
        user = get_user_guid(email)
        
        if user == "Not found"
          line "User not found!"
        else
          return unless input[:really, user, role, org]
          case role
            when "users"
              line "checking if #{c(user.email, :name)} has any other roles in #{c(org.name, :name)}"
              if check_other_org_roles(user, org)
                line "User, #{c(user.email, :name)}, has additional roles within the organization."
                line "If you want to remove the user from all roles within the organization, rerun the command with the #{b("'--recursive'")} flag."
              else
                line "checking if #{c(user.email, :name)} has any roles in any spaces within #{c(org.name, :name)}"
                if check_other_space_roles(user, org)
                  line "User, #{c(user.email, :name)}, has additional space roles within the organization."
                  line "If you want to remove the user from all space roles within the organization, rerun the command with the #{b("'--recursive'")} flag."
                else
                  with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}") do
                  org.remove_user(user)
              end
                end
              end

            when "managers"
              with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}") do
                org.remove_manager(user)
              end
            when "auditors"
              with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}") do
                org.remove_auditor(user)
              end
            when "billing_managers"
              with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}") do
                org.remove_billing_manager(user)
              end
          end
        end
      end
      
          private

      def display_user(u)
        if quiet?
          puts u.email
        else
          indented do
            line "#{c(u.email, :name)}"
          end
        end
      end

      def ask_role
        ask("User role:", 
        :choices => role_choices,
        :default => role_choices.first,
        :allow_other => false)
      end
      
      def ask_action
        ask("Action to take:",
        :choices => action_choices,
        :default => action_choices.first,
        :allow_other => false)
      end  

      def ask_email
        ask("User's email address:")
      end
      
      def ask_really(user, role, org)
        ask("Really remove #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}?", :default => false)
      end
      
      def get_user_guid(user)
        users = client.users(:depth => 0)
          users.each do |u|
            
            if u.email == user
              return u
            end
          end

        return "Not found"  
      end
      
      #Make sure the user doesn't have any other roles in the org before removing them.
      def check_other_org_roles(user, org)
        users = org.auditors + org.managers + org.billing_managers
        users = users.uniq
          users.each do |u|
            if u.email == user.email
              if input[:recursive]
                line "Removing user roles from #{c(org.name, :name)}..."
                if org.auditors.include? u
                  invoke :org_roles, :organization => org, :action => "remove", :role => "auditors", :email => u.email, :really => true
                end
                if org.managers.include? u
                  invoke :org_roles, :organization => org, :action => "remove", :role => "managers", :email => u.email, :really => true
                end
                if org.billing_managers.include? u
                  invoke :org_roles, :organization => org, :action => "remove", :role => "billing_managers", :email => u.email, :really => true
                end
                return false
              end             
              return true
            end         
          end
        return false
      end

      #Make sure the user doesn't have any other space roles in the org before removing them.
      def check_other_space_roles(user, org)
        spaces = org.spaces(:depth => 0)
        spaces.each do |s|
          users = s.auditors + s.managers + s.developers
          users = users.uniq
            users.each do |u|
              if u.email == user.email
                if input[:recursive]
                  line "Removing user roles from #{c(org.name, :name)}, #{c(s.name, :name)}..."
                  if s.auditors.include? u
                    invoke :space_roles, :organization => org, :space => s, :action => "remove", :role => "auditors", :email => u.email, :really => true
                  end
                  if s.managers.include? u
                    invoke :space_roles, :organization => org, :space => s, :action => "remove", :role => "managers", :email => u.email, :really => true
                  end
                  if s.developers.include? u
                    invoke :space_roles, :organization => org, :space => s, :action => "remove", :role => "developers", :email => u.email, :really => true
                  end
                  return false
                end
                return true
              end           
            end
          return false
        end
      end
      
    end
  end
end
