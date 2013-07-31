require "cf/cli/user/base"

module CF::User
  class Passwd < Base
    desc "Update the current user's password"
    group :admin, :user
    input :password, :desc => "Current password"
    input :new_password, :desc => "New password"
    input :verify, :desc => "Repeat new password"

    def passwd
      password = input[:password]
      new_password = input[:new_password]

      validate_password! new_password

      with_progress("Changing password") do
        client.current_user.change_password!(new_password, password)
      end
    end

    private

    def ask_password
      ask("Current Password", :echo => "*", :forget => true)
    end

    def ask_new_password
      ask("New Password", :echo => "*", :forget => true)
    end

    def ask_verify
      ask("Verify Password", :echo => "*", :forget => true)
    end
  end
end
