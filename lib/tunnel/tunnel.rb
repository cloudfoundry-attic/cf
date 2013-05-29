require "addressable/uri"
require "restclient"
require "uuidtools"

require "caldecott-client"

class CFTunnel
  HELPER_NAME = "caldecott"
  HELPER_APP = File.expand_path("../helper-app", __FILE__)

  # bump this AND the version info reported by HELPER_APP/server.rb
  # this is to keep the helper in sync with any updates here
  HELPER_VERSION = "0.0.4"

  def initialize(client, service, port = 10000)
    @client = client
    @service = service
    @port = port
  end

  def open!
    if helper
      auth = helper_auth

      unless helper_healthy?(auth)
        delete_helper
        auth = create_helper
      end
    else
      auth = create_helper
    end

    bind_to_helper if @service && !helper_already_binds?

    info = get_connection_info(auth)

    start_tunnel(info, auth)

    info
  end

  def wait_for_start
    10.times do |n|
      begin
        TCPSocket.open("localhost", @port).close
        return true
      rescue => e
        sleep 1
      end
    end

    raise "Could not connect to local tunnel."
  end

  def wait_for_end
    if @local_tunnel_thread
      @local_tunnel_thread.join
    else
      raise "Tunnel wasn't started!"
    end
  end

  PORT_RANGE = 10
  def pick_port!(port = @port)
    original = port

    PORT_RANGE.times do |n|
      begin
        TCPSocket.open("localhost", port)
        port += 1
      rescue
        return @port = port
      end
    end

    @port = grab_ephemeral_port
  end

  private

  def helper
    @helper ||= @client.app_by_name(HELPER_NAME)
  end

  def create_helper
    auth = UUIDTools::UUID.random_create.to_s
    push_helper(auth)
    start_helper
    auth
  end

  def helper_auth
    helper.env["CALDECOTT_AUTH"]
  end

  def helper_healthy?(token)
    return false unless helper.healthy?

    begin
      response = RestClient.get(
        "#{helper_url}/info",
        "Auth-Token" => token
      )

      info = JSON.parse(response)
      if info["version"] == HELPER_VERSION
        true
      else
        stop_helper
        false
      end
    rescue RestClient::Exception
      stop_helper
      false
    end
  end

  def helper_already_binds?
    helper.binds? @service
  end

  def push_helper(token)
    app = @client.app
    app.name = HELPER_NAME
    app.command = "bundle exec ruby server.rb"
    app.total_instances = 1
    app.memory = 128
    app.env = {"CALDECOTT_AUTH" => token}

    space = app.space = @client.current_space
    app.create!

    app.bind(@service) if @service

    domain = @client.domains.find { |d| d.owning_organization == nil }

    app.create_route(:domain => domain, :space => space, :host => random_helper_url)

    begin
      app.upload(HELPER_APP)
      invalidate_tunnel_app_info
    rescue
      app.delete!
      raise
    end
  end

  def delete_helper
    helper.delete!
    invalidate_tunnel_app_info
  end

  def stop_helper
    helper.stop!
    invalidate_tunnel_app_info
  end

  TUNNEL_CHECK_LIMIT = 60
  def start_helper
    helper.start!

    seconds = 0
    until helper.healthy?
      sleep 1
      seconds += 1
      if seconds == TUNNEL_CHECK_LIMIT
        raise "Helper application failed to start."
      end
    end

    invalidate_tunnel_app_info
  end

  def bind_to_helper
    helper.bind(@service)
    helper.restart!
  end

  def invalidate_tunnel_app_info
    @helper_url = nil
    @helper = nil
  end

  def helper_url
    return @helper_url if @helper_url

    tun_url = helper.url

    ["https", "http"].each do |scheme|
      url = "#{scheme}://#{tun_url}"
      begin
        RestClient.get(url)

      # https failed
      rescue Errno::ECONNREFUSED

      # we expect a 404 since this request isn't auth'd
      rescue RestClient::ResourceNotFound
        return @helper_url = url
      end
    end

    raise "Cannot determine URL for #{tun_url}"
  end

  def get_connection_info(token)
    response = nil
    10.times do
      begin
        response =
          RestClient.get(
            helper_url + "/" + safe_path("services", @service.name),
            "Auth-Token" => token)

        break
      rescue RestClient::Exception => e
        sleep 1
      end
    end

    unless response
      raise "Remote tunnel helper is unaware of #{@service.name}!"
    end

    is_v2 = @client.is_a?(CFoundry::V2::Client)

    info = JSON.parse(response)
    case (is_v2 ? @service.service_plan.service.label : @service.vendor)
    when "rabbitmq"
      uri = Addressable::URI.parse info["url"]
      info["hostname"] = uri.host
      info["port"] = uri.port
      info["vhost"] = uri.path[1..-1]
      info["user"] = uri.user
      info["password"] = uri.password
      info.delete "url"

    # we use "db" as the "name" for mongo
    # existing "name" is junk
    when "mongodb"
      info["name"] = info["db"]
      info.delete "db"

    # our "name" is irrelevant for redis
    when "redis"
      info.delete "name"

    when "filesystem"
      raise "Tunneling is not supported for this type of service"
    end

    ["hostname", "port", "password"].each do |k|
      raise "Could not determine #{k} for #{@service.name}" if info[k].nil?
    end

    info
  end

  def start_tunnel(conn_info, auth)
    @local_tunnel_thread = Thread.new do
      Caldecott::Client.start({
        :local_port => @port,
        :tun_url => helper_url,
        :dst_host => conn_info["hostname"],
        :dst_port => conn_info["port"],
        :log_file => STDOUT,
        :log_level => ENV["CF_TUNNEL_DEBUG"] || "ERROR",
        :auth_token => auth,
        :quiet => true
      })
    end

    at_exit { @local_tunnel_thread.kill }
  end

  def random_helper_url
    random = sprintf("%x", rand(1000000))
    "caldecott-#{random}"
  end

  def safe_path(*segments)
    segments.flatten.collect { |x|
      URI.encode x.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")
    }.join("/")
  end

  def grab_ephemeral_port
    socket = TCPServer.new("0.0.0.0", 0)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    Socket.do_not_reverse_lookup = true
    socket.addr[1]
  ensure
    socket.close
  end
end
