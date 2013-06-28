require "yaml"
require "multi_json"
require "cf/cli"

require "micro-cf-plugin/help"
require "micro-cf-plugin/micro/micro"
require "micro-cf-plugin/micro/vmrun"
require "micro-cf-plugin/micro/switcher/base"
require "micro-cf-plugin/micro/switcher/darwin"
require "micro-cf-plugin/micro/switcher/linux"
require "micro-cf-plugin/micro/switcher/windows"

module CFMicro
  class McfCommand < CF::CLI
    MICRO_FILE = '~/.cf/micro.yml'

    desc "Display Micro Cloud Foundry VM status"
    group :micro
    input :vmx, :argument => :required,
      :desc => "Path to micro.vmx"
    input :password, :argument => :optional,
      :desc => "Cleartext password for guest VM vcap user"
    def micro_status
      mode = runner.offline? ? 'offline' : 'online'

      line "Micro Cloud Foundry VM currently in #{b(mode)} mode"
      # should the VMX path be unescaped?
      line "VMX Path: #{c(runner.vmx, :good)}"
      line "Domain: #{c(runner.domain, :good)}"
      line "IP Address: #{c(runner.ip, :good)}"
    end

    desc "Micro Cloud Foundry offline mode"
    group :micro
    input :vmx, :argument => :required,
      :desc => "Path to micro.vmx"
    input :password, :argument => :optional,
      :desc => "Cleartext password for guest VM vcap user"
    def micro_offline
      if !runner.nat?
        if ask("Reconfigure MCF VM network to nat mode and reboot?", :default => true)
          with_progress("Rebooting MCF VM") do
            runner.reset_to_nat!
          end
        else
          fail "Aborted"
        end
      end

      with_progress("Setting MCF VM to offline mode") do
        runner.offline!
      end

      with_progress("Setting host DNS server") do
        runner.set_host_dns!
      end
    end

    desc "Micro Cloud Foundry online mode"
    group :micro
    input :vmx, :argument => :required,
      :desc => "Path to micro.vmx"
    input :password, :argument => :optional,
      :desc => "Cleartext password for guest VM vcap user"
    def micro_online
      runner
      with_progress("Unsetting host DNS server") do
        runner.unset_host_dns!
      end

      with_progress("Setting MCF VM to online mode") do
        runner.online!
      end
    end

    def runner
      return @runner if @runner

      config = build_config
      @runner = switcher(config)
      check_vm_running
      store_config(config)

      @runner
    end

    def check_vm_running
      unless runner.running?
        if ask("MCF VM is not running. Do you want to start it?", :default => true)
          with_progress("Starting MCF VM") do
            runner.start!
          end
        else
          fail "MCF VM needs to be running."
        end
      end

      unless runner.ready?
        fail "MCF VM initial setup needs to be completed before using 'cf micro'"
      end
    end

    def switcher(config)
      case McfCommand.platform
      when :darwin
        CFMicro::Switcher::Darwin.new(config)
      when :linux
        CFMicro::Switcher::Linux.new(config)
      when :windows
        CFMicro::Switcher::Windows.new(config)
      when :dummy # for testing only
        CFMicro::Switcher::Dummy.new(config)
      else
        fail "unsupported platform: #{McfCommand.platform}"
      end
    end

    # Returns the configuration needed to run the micro related subcommands.
    # First loads saved config from file (if there is any), then overrides
    # loaded values with command line arguments, and finally tries to guess
    # in case neither was used:
    #   vmx       location of micro.vmx file
    #   vmrun     location of vmrun command
    #   password  password for vcap user (in the guest vm)
    #   platform  current platform
    def build_config
      conf = micro # returns {} if there isn't a saved config

      override(conf, :vmx, true) do
        locate_vmx(McfCommand.platform)
      end

      override(conf, :vmrun, true) do
        CFMicro::VMrun.locate(McfCommand.platform)
      end

      override(conf, :password) do
        ask("Please enter your MCF VM password (vcap user) password", :echo => "*")
      end

      conf[:platform] = McfCommand.platform

      conf
    end

    # Save the cleartext password if --save is supplied.
    # Note: it is due to vix we have to use a cleartext password :(
    # Only if --password is used and not --save is the password deleted from the
    # config file before it is stored to disk.
    def store_config(config)
      if input[:save]
        warn("cleartext password saved in: #{MICRO_FILE}")
      end

      store_micro(config)
    end

    # override with command line arguments and yield the block in case the option isn't set
    def override(config, option, escape=false, &blk)
      # override if given on the command line
      if opt = input[option]
        opt = CFMicro.escape_path(opt) if escape
        config[option] = opt
      end
      config[option] = yield unless config[option]
    end

    def locate_vmx(platform)
      paths = YAML.load_file(CFMicro.config_file('paths.yml'))
      vmx_paths = paths[platform.to_s]['vmx']
      vmx = CFMicro.locate_file('micro.vmx', 'micro', vmx_paths)
      fail "Unable to locate micro.vmx, please supply --vmx option" unless vmx
      vmx
    end

    def self.platform
      case RUBY_PLATFORM
      when /darwin/  # x86_64-darwin11.2.0
        :darwin
      when /linux/   # x86_64-linux
        :linux
      when /mingw|mswin32|cygwin/ # i386-mingw32
        :windows
      else
        RUBY_PLATFORM
      end
    end

    def micro
      micro_file = File.expand_path(MICRO_FILE)
      return {} unless File.exists? micro_file
      contents = File.read(micro_file).strip
      MultiJson.load(contents)
    end

    def store_micro(micro)
      micro_file = File.expand_path(MICRO_FILE)
      File.open(micro_file, 'w') do |file|
        file.write(MultiJson.dump(micro))
      end
    end
  end
end
