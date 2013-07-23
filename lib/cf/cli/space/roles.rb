require "cf/cli/space/base"

module CF
  module Space
    class Roles < Base
      desc "Manage the roles of a space"
      group :spaces
      input :organization, :desc => "Organization to manage",
        :argument => :optional, :aliases => ["--org", "-o"],
        :default => proc { client.current_organization },
        :from_given => by_name(:organization)
      input :space, :desc => "Space to manage",
        :argument => :optional, :aliases => ["--space", "-s"],
        #:default => proc { client.current_space },
        :from_given => space_by_name
      input :role, :desc => "Target role: developers, managers, auditors",
        :argument => :optional, :aliases => ["--role", "-r"]
      input :action, :desc => "Action to take: list, add, remove",
        :argument => :optional, :aliases => ["--action", "-a"]
      input :email, :desc => "User's email address",
        :argument => :optional, :aliases => ["--email", "-e"]
      input :recursive, :desc => "Delete recursively",
            :default => false, :forget => true
      input :really, :type => :boolean, :forget => true, :hidden => true,
            :default => proc { force? || interact }

      def space_roles

        org = input[:organization]
        space = input[:space, org]
        action = input[:action]
        role = input[:role]

        if not valid_role(role)
          line "Invalid role specified.  Valid roles are: developers, managers, and auditors"
          return
        end
        
        unless space
          return if quiet?
          fail "No current space."
        end

        if quiet?
          puts space.name
          return
        end

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
            action_list(role, org, space)
          when "add"
            action_add(role, org, space)
          when "remove"
            action_remove(role, org, space)
        end
      end

      def action_choices
        ["list", "add", "remove"]
      end
      
      def role_choices
        ["developers", "managers", "auditors"]
      end

      def action_list(role, org, space)

        users = 
          with_progress("Getting #{c(role, :name)} for #{c(space.name, :name)} in #{c(org.name, :name)}" ) do
            case role
              when "developers"
                space.developers(:depth => 0)
              when "managers"
                space.managers(:depth => 0)
              when "auditors"
                space.auditors(:depth => 0)
            end
          end

          spaced(users) do |u|
            display_user(u)
          end
      end

      def action_add(role, org, space)
        email = input[:email]
        user = get_user_guid(org, email)
        
        if user == "Not found"
          line "User not found!"
        elsif user == nil
          line "Nothing to do..."
        else
          case role
            when "developers"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}, #{c(space.name, :name)}") do
                space.add_developer(user)
              end
            when "managers"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}, #{c(space.name, :name)}") do
                space.add_manager(user)
              end
            when "auditors"
              with_progress("Adding #{c(user.email, :name)} to #{c(role, :name)} in #{c(org.name, :name)}, #{c(space.name, :name)}") do
                space.add_auditor(user)
              end
          end
        end
      end

      def action_remove(role, org, space)
        email = input[:email]
        user = get_user_guid(org, email)

        if user == "Not found"
          line "User not found!"
        else
          return unless input[:really, user, role, org, space]
          case role
            when "developers"
              with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}, #{c(space.name, :name)}") do
                user.remove_space(space)
              end
            when "managers"
              with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}, #{c(space.name, :name)}") do
                user.remove_managed_space(space)
              end
            when "auditors"
              with_progress("Removing #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name, :name)}, #{c(space.name, :name)}") do
                user.remove_audited_space(space)
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

      def ask_space(org)
        spaces = org.spaces
        fail "No spaces." if spaces.empty?

        ask("Which space?", :choices => spaces.sort_by(&:name),
            :display => proc(&:name))
      end
      
      def ask_really(user, role, org, space)
        ask("Really remove #{c(user.email, :name)} from #{c(role, :name)} in #{c(org.name)}, #{c(space.name)}?", :default => false)
      end
      
      def ask_add_to_org(email, org)
         ask("Would you like to add #{c(email, :name)} to #{c(org.name, :name)}?",
         :choices => ["yes", "no"], :default => "yes", :allow_other => false)
      end

      def get_user_guid(org, user)
        users = org.users(:depth => 0)
          users.each do |u|
            if u.email == user
              return u
            end
          end
        users = client.users(:depth => 0)
          users.each do |u|
            if u.email == user
              if input[:recursive]
                line "Adding #{c(u.email, :name)} to #{c(org.name, :name)}..."
                invoke :org_roles, :organization => org, :action => "add", :role => "users", :email => u.email
              else
                line "The user: #{c(u.email, :name)} is a valid system user but is not a member of #{c(org.name, :name)}"
                  if ask_add_to_org(u.email, org) == "yes"
                    invoke :org_roles, :organization => org, :action => "add", :role => "users", :email => u.email
                  else
                    return nil
                  end
              end     
              return u
            end
          end
        return "Not found"  
      end
      def valid_role(role)
        if not role_choices.include? role
          return false
        end
        return true
      end
    end
  end
end
