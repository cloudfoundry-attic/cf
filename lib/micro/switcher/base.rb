require "micro/errors"

module CFMicro::Switcher
  class Base

    def initialize(config)
      @config = config

      @vmrun = CFMicro::VMrun.new(config)
    end

    #wrapper methods
    def vmx
      @vmrun.vmx
    end

    def domain
      @vmrun.domain
    end

    def ip
      @vmrun.ip
    end

    def running?
      @vmrun.running?
    end

    def start!
      @vmrun.start!
    end

    def ready?
      @vmrun.ready?
    end

    def offline?
      @vmrun.offline?
    end

    def nat?
      @config['online_connection_type'] ||= @vmrun.connection_type
      @config["online_connection_type"] == "nat"
    end

    def reset_to_nat!
      @vmrun.connection_type = 'nat'
      @vmrun.reset
    end

    def set_host_dns!
      @config['domain'] ||= @vmrun.domain
      @config['ip'] ||= @vmrun.ip
      set_nameserver(@config['domain'], @config['ip'])
    end

    def unset_host_dns!
      @config['domain'] ||= @vmrun.domain
      @config['ip'] ||= @vmrun.ip
      unset_nameserver(@config['domain'], @config['ip'])
    end

    def offline!
      if  @vmrun.offline?
        raise CFMicro::MCFError, "Micro Cloud Foundry VM already in offline mode"
      else
        @vmrun.offline!
      end
    end

    def online!
      if @vmrun.offline?
        @vmrun.online!
      else
        raise CFMirco::MCFError, "Micro Cloud Foundry already in online mode"
      end
    end
  end
end
