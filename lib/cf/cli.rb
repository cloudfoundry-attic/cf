require "yaml"
require "socket"
require "net/http"
require "multi_json"
require "fileutils"

require "mothership"

require "cfoundry"

require "cf/constants"
require "cf/errors"
require "cf/spacing"

require "cf/cli/help"
require "cf/cli/interactive"


$cf_asked_auth = false

module CF
  class CLI < Mothership
    include CF::Interactive
    include CF::Spacing

    option :help, :desc => "Show command usage", :alias => "-h",
      :default => false

    option :http_proxy, :desc => "Connect though an http proxy server", :alias => "--http-proxy",
      :value => :http_proxy

    option :https_proxy, :desc => "Connect though an https proxy server", :alias => "--https-proxy",
      :value => :https_proxy

    option :version, :desc => "Print version number", :alias => "-v",
      :default => false

    option :verbose, :desc => "Print extra information", :alias => "-V",
      :default => false

    option :force, :desc => "Skip interaction when possible", :alias => "-f",
      :type => :boolean, :default => proc { input[:script] }

    option :debug, :desc => "Print full stack trace (instead of crash log)",
           :type => :boolean, :default => false

    option :quiet, :desc => "Simplify output format", :alias => "-q",
      :type => :boolean, :default => proc { input[:script] }

    option :script, :desc => "Shortcut for --quiet and --force",
      :type => :boolean, :default => proc { !$stdout.tty? }

    option :color, :desc => "Use colorful output",
      :type => :boolean, :default => proc { !input[:quiet] }

    option :trace, :desc => "Show API traffic", :alias => "-t",
      :default => false


    def default_action
      if input[:version]
        line "cf #{VERSION}"
      else
        super
      end
    end

    def check_target
      unless client && client.target
        fail "Please select a target with 'cf target'."
      end
    end

    def check_logged_in
      unless client.logged_in?
        if force?
          fail "Please log in with 'cf login'."
        else
          line c("Please log in first to proceed.", :warning)
          line
          invoke :login
          invalidate_client
        end
      end
    end

    def precondition
      check_target
      check_logged_in

      unless client.current_organization
        fail "Please select an organization with 'cf target --organization ORGANIZATION_NAME'. (Get organization names from 'cf orgs'.)"
      end

      unless client.current_space
        fail "Please select a space with 'cf target --space SPACE_NAME'. (Get space names from 'cf spaces'.)"
      end
    end

    def wrap_errors
      yield
    rescue CFoundry::Timeout => e
      err(e.message)
    rescue Interrupt
      exit_status 130
    rescue Mothership::Error
      raise
    rescue UserError => e
      log_error(e)
      err e.message
    rescue SystemExit
      raise
    rescue UserFriendlyError => e
      err e.message
    rescue CFoundry::InvalidAuthToken => e
      line
      line c("Invalid authentication token. Try logging in again with 'cf login'. If problems continue, please contact your Cloud Operator.", :warning)
    rescue CFoundry::Forbidden => e
      if !$cf_asked_auth
        $cf_asked_auth = true

        line
        line c("Not authenticated! Try logging in:", :warning)

        if !force?
          # TODO: there's no color here; global flags not being passed
          # through (mothership bug?)
          invoke :login
        end

        retry
      end

      log_error(e)

      err "Denied: #{e.description}"

    rescue Exception => e
      log_error(e)

      msg = e.class.name
      msg << ": #{e}" unless e.to_s.empty?
      msg << "\nFor more information, see #{CF::CRASH_FILE}"
      err msg

      raise if debug?
    end

    def execute(cmd, argv, global = {})
      if input[:help]
        invoke :help, :command => cmd.name.to_s
      else
        wrap_errors do
          @command = cmd
          precondition

          save_token_if_it_changes do
            super
          end
        end
      end
    end

    def save_token_if_it_changes
      return yield unless client && client.token

      before_token = client.token

      yield

      after_token = client.token

      return unless after_token

      if before_token != after_token
        info = target_info
        info[:token] = after_token.auth_header
        save_target_info(info)
      end
    end

    def log_error(e)
      ensure_config_dir

      msg = e.class.name
      msg << ": #{e}" unless e.to_s.empty?

      crash_file = File.expand_path(CF::CRASH_FILE)

      FileUtils.mkdir_p(File.dirname(crash_file))

      File.open(crash_file, "w") do |f|
        f.puts "Time of crash:"
        f.puts "  #{Time.now}"
        f.puts ""
        f.puts msg
        f.puts ""

        if e.respond_to?(:request_trace)
          f.puts "<<<"
          f.puts e.request_trace
        end

        if e.respond_to?(:response_trace)
          f.puts e.response_trace
          f.puts ">>>"
          f.puts ""
        end

        cf_dir = File.expand_path("../../../..", __FILE__) + "/"
        e.backtrace.each do |loc|
          if loc =~ /\/gems\//
            f.puts loc.sub(/.*\/gems\//, "")
          else
            f.puts loc.sub(cf_dir, "")
          end
        end
      end
    end

    def quiet?
      input[:quiet]
    end

    def force?
      input[:force]
    end

    def debug?
      !!input[:debug]
    end

    def color_enabled?
      input[:color]
    end

    def verbose?
      input[:verbose]
    end

    def user_colors
      return @user_colors if @user_colors

      colors = File.expand_path(COLORS_FILE)

      @user_colors = super.dup

      # most terminal schemes are stupid, so use cyan instead
      @user_colors.each do |k, v|
        if v == :blue
          @user_colors[k] = :cyan
        end
      end

      if File.exists?(colors)
        YAML.load_file(colors).each do |k, v|
          @user_colors[k.to_sym] = v.to_sym
        end
      end

      @user_colors
    end

    def err(msg, status = 1)
      $stderr.puts c(msg, :error)
      exit_status status
    end

    def fail(msg)
      raise UserError, msg
    end

    def table(headers, rows)
      tabular(
        !quiet? && headers.collect { |h| h && b(h) },
        *rows)
    end

    def name_list(xs)
      if xs.empty?
        d("none")
      else
        xs.collect { |x| c(x.name, :name) }.join(", ")
      end
    end

    def sane_target_url(url)
      unless url =~ /^https?:\/\//
        begin
          TCPSocket.new(url, Net::HTTP.https_default_port)
          url = "https://#{url}"
        rescue Errno::ECONNREFUSED, SocketError, Timeout::Error
          url = "http://#{url}"
        end
      end

      url.gsub(/\/$/, "")
    end

    def one_of(*paths)
      paths.each do |p|
        exp = File.expand_path(p)
        return exp if File.exist? exp
      end

      File.expand_path(paths.first)
    end

    def client_target
      if File.exists?(target_file)
        File.read(target_file).chomp
      end
    end

    def ensure_config_dir
      config = File.expand_path(CF::CONFIG_DIR)
      FileUtils.mkdir_p(config) unless File.exist? config
    end

    def set_target(url)
      ensure_config_dir

      File.open(File.expand_path(CF::TARGET_FILE), "w") do |f|
        f.write(sane_target_url(url))
      end

      invalidate_client
    end

    def targets_info
      new_toks = File.expand_path(CF::TOKENS_FILE)

      info =
        if File.exist? new_toks
          YAML.load_file(new_toks)
        end

      info ||= {}

      normalize_targets_info(info)
    end

    def normalize_targets_info(info_by_url)
      info_by_url.reduce({}) do |hash, pair|
        key, value = pair
        hash[key] = value.is_a?(String) ? { :token => value } : value
        hash
      end
    end

    def target_info(target = client_target)
      targets_info[target] || {}
    end

    def save_targets(ts)
      ensure_config_dir

      File.open(File.expand_path(CF::TOKENS_FILE), "w") do |io|
        YAML.dump(ts, io)
      end
    end

    def save_target_info(info, target = client_target)
      ts = targets_info
      ts[target] = info
      save_targets(ts)
    end

    def remove_target_info(target = client_target)
      ts = targets_info
      ts.delete target
      save_targets(ts)
    end

    def invalidate_client
      @@client = nil
      client
    end

    def client(target = client_target)
      return @@client if defined?(@@client) && @@client
      return unless target

      info = target_info(target)
      token = info[:token] && CFoundry::AuthToken.from_hash(info)

      fail "V1 targets are no longer supported." if info[:version] == 1

      @@client = CFoundry::V2::Client.new(target, token)

      @@client.http_proxy = input[:http_proxy] || ENV['HTTP_PROXY'] || ENV['http_proxy']
      @@client.https_proxy = input[:https_proxy] || ENV['HTTPS_PROXY'] || ENV['https_proxy']
      @@client.trace = input[:trace]

      uri = URI.parse(target)
      @@client.log = File.expand_path("#{LOGS_DIR}/#{uri.host}.log")

      unless info.key? :version
        info[:version] = @@client.version
        save_target_info(info, target)
      end

      if (org = info[:organization])
        @@client.current_organization = @@client.organization(org)
      end

      if (space = info[:space])
        @@client.current_space = @@client.space(space)
      end

      @@client
    rescue CFoundry::InvalidTarget
    end

    def fail_unknown(display, name)
      fail("Unknown #{display} '#{name}'.")
    end

    class << self
      def client
        @@client
      end

      def client=(c)
        @@client = c
      end

      private

      def find_by_name(display, &blk)
        proc { |name, *args|
          choices, _ = args
          choices ||= instance_exec(&blk) if block_given?

          choices.find { |c| c.name == name } ||
            fail_unknown(display, name)
        }
      end

      def by_name(what, display = what)
        proc { |name, *_|
          client.send(:"#{what}_by_name", name) ||
            fail_unknown(display, name)
        }
      end

      def find_by_name_insensitive(display, &blk)
        proc { |name, *args|
          choices, _ = args
          choices ||= instance_exec(&blk) if block_given?

          choices.find { |c| c.name.upcase == name.upcase } ||
            fail_unknown(display, name)
        }
      end
    end

    private

    def target_file
      File.expand_path(CF::TARGET_FILE)
    end

    def tokens_file
      File.expand_path(CF::TOKENS_FILE)
    end
  end
end
