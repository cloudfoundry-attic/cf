require "cf/cli"

module CFAdmin
  class ServiceAuthToken < CF::CLI
    def precondition
      unless File.exists? target_file
        fail "Please select a target with 'cf target'."
      end

      unless client.logged_in?
        fail "Please log in with 'cf login'."
      end
    end


    desc "List service auth tokens"
    group :admin
    def service_auth_tokens
      spaced(client.service_auth_tokens) do |t|
        line "#{c(t.label, :name)}:"

        indented do
          line "guid: #{t.guid}"
          line "provider: #{t.provider}"
        end
      end
    end


    desc "Create a service auth token"
    group :admin
    input(:label, :argument => :optional, :desc => "Auth token label") {
      ask("Label")
    }
    input :provider, :argument => :optional, :default => "core",
      :desc => "Auth token provider"
    input(:token, :desc => "Auth token value") {
      ask("Token")
    }
    def create_service_auth_token
      sat = client.service_auth_token
      sat.label = input[:label]
      sat.provider = input[:provider]
      sat.token = input[:token]

      with_progress("Creating service auth token") do
        sat.create!
      end
    end


    desc "Update a service auth token"
    group :admin
    input(:service_auth_token, :argument => :optional,
          :from_given => proc { |guid| client.service_auth_token(guid) },
          :desc => "Auth token to delete") {
      tokens = client.service_auth_tokens
      fail "No tokens!" if tokens.empty?

      ask("Which token?", :choices => tokens, :display => proc(&:label))
    }
    input(:token, :desc => "Auth token value") {
      ask("Token")
    }
    def update_service_auth_token
      sat = input[:service_auth_token]
      sat.token = input[:token]

      with_progress("Updating token #{c(sat.label, :name)}") do
        sat.update!
      end
    end


    desc "Delete a service auth token"
    group :admin
    input(:service_auth_token, :argument => :optional,
          :from_given => proc { |guid| client.service_auth_token(guid) },
          :desc => "Auth token to delete") {
      tokens = client.service_auth_tokens
      fail "No tokens!" if tokens.empty?

      ask("Which token?", :choices => tokens, :display => proc(&:label))
    }
    def delete_service_auth_token
      sat = input[:service_auth_token]

      with_progress("Deleting token #{c(sat.label, :name)}") do
        sat.delete!
      end
    end
  end
end
