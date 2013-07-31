require "cf/cli/user/base"

module CF::User
  class Create < Base
    desc "Create a user"
    group :admin, :user
    input :email, :desc => "User email", :argument => :optional
    input :password, :desc => "User password"
    input :verify, :desc => "Repeat password"
    input :organization, :desc => "User organization",
      :aliases => %w{--org -o},
      :default => proc { client.current_organization },
      :from_given => by_name(:organization)

    def create_user
      org = CF::Populators::Organization.new(input).populate_and_save!
      email = input[:email]
      password = input[:password]

      if !force? && password != input[:verify]
        fail "Passwords don't match."
      end

      user = nil
      with_progress("Creating user") do
        user = client.register(email, password)
      end

      with_progress("Adding user to #{org.name}") do
        user.audited_organizations = user.managed_organizations = user.organizations = [org]
        user.update!
      end
    end

    alias_command :add_user, :create_user

    private

    def ask_email
      ask("Email")
    end

    def ask_password
      ask("Password", :echo => "*", :forget => true)
    end

    def ask_verify
      ask("Verify Password", :echo => "*", :forget => true)
    end
  end
end
