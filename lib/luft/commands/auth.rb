require "luft/commands/base"

# authentication (login, logout)
#
class Luft::Command::Auth < Luft::Command::Base

  # auth
  #
  # Authenticate, display token and current user
  def index
    validate_arguments!

    Luft::Command::Help.new.send(:help_for_command, current_command)
  end

  # auth:login
  #
  # log in with your luft credentials
  #
  #Example:
  #
  # $ luft auth:login
  # Enter your Luft credentials:
  # Email: email@example.com
  # Password: ********
  # Authentication successful.
  #
  def login
    validate_arguments!

    Luft::Auth.login
    display "Authentication successful."
  end

  alias_command "login", "auth:login"

  # auth:logout
  #
  # clear local authentication credentials
  #
  #Example:
  #
  # $ luft auth:logout
  # Local credentials cleared.
  #
  def logout
    validate_arguments!

    Luft::Auth.logout
    display "Local credentials cleared."
  end

  alias_command "logout", "auth:logout"
end

