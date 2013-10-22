require "cf/cli/app/base"

module CF::App
  class Start < Base
    APP_CHECK_LIMIT = 60

    desc "Start an application"
    group :apps, :manage
    input :apps, :desc => "Applications to start", :argument => :splat,
          :singular => :app, :from_given => by_name(:app)
    input :debug_mode, :desc => "Debug mode to start in", :aliases => "-d"
    input :all, :desc => "Start all applications", :default => false
    def start
      apps = input[:all] ? client.apps : input[:apps]
      fail "No applications given." if apps.empty?

      spaced(apps) do |app|
        app = filter(:start_app, app)

        switch_mode(app, input[:debug_mode])

        if app.started?
          err "Application #{b(app.name)} is already started."
          next
        end

        log = start_app(app)
        stream_start_log(log) if log
        check_application(app)

        if !app.debug_mode.nil? && app.debug_mode != "none" && !quiet?
          line
          invoke :instances, :app => app
        end
      end
    end

    private

    def start_app(app)
      log = nil
      with_progress("Preparing to start #{c(app.name, :name)}") do
        app.start! do |url|
          log = url
        end
      end
      log
    end

    def stream_start_log(log)
      offset = 0

      while true
        begin
          client.stream_url(log + "&tail&tail_offset=#{offset}") do |out|
            offset += out.size
            print out
          end
        rescue Timeout::Error
        end
      end
    rescue CFoundry::APIError
    end

    # set app debug mode, ensuring it's valid, and shutting it down
    def switch_mode(app, mode)
      mode = "run" if mode == "" # no value given

      return false if app.debug == mode

      if mode == "none"
        with_progress("Removing debug mode") do
          app.debug = mode
          app.stop! if app.started?
        end

        return true
      end

      with_progress("Switching mode to #{c(mode, :name)}") do |s|
        app.debug = mode
        app.stop! if app.started?
      end
    end

    def check_application(app)
      if app.debug == "suspend"
        line "Application is in suspended debugging mode."
        line "It will wait for you to attach to it before starting."
        return
      end

      print("Checking status of app '#{c(app.name, :name)}'...")

      seconds = 0
      @first_time_after_staging_succeeded = true

      begin
        instances = []
        while true
          if any_instance_flapping?(instances) || seconds == APP_CHECK_LIMIT
            err "Push unsuccessful."
            line "#{c("TIP: The system will continue to attempt restarting all requested app instances that have crashed. Try 'cf app' to monitor app status. To troubleshoot crashes, try 'cf events' and 'cf crashlogs'.", :warning)}"
            return
          end

          begin
            return unless instances = app.instances

            indented { print_instances_summary(instances) }

            if one_instance_running?(instances)
              line "#{c("Push successful! App '#{app.name}' available at #{app.host}.#{app.domain}", :good)}"
              unless all_instances_running?(instances)
                line "#{c("TIP: The system will continue to start all requested app instances. Try 'cf app' to monitor app status.", :warning)}"
              end
              return
            end
          rescue CFoundry::NotStaged
            print (".")
          end

          sleep 1
          seconds += 1
        end
      rescue CFoundry::StagingError
        err "Application failed to stage"
      end
    end

    def one_instance_running?(instances)
      instances.any? { |i| i.state == "RUNNING" }
    end

    def all_instances_running?(instances)
      instances.all? { |i| i.state == "RUNNING" }
    end

    def any_instance_flapping?(instances)
      instances.any? { |i| i.state == "FLAPPING" }
    end

    def print_instances_summary(instances)

      if @first_time_after_staging_succeeded
        line
        @first_time_after_staging_succeeded = false
      end

      counts = Hash.new { 0 }
      instances.each do |i|
        counts[i.state] += 1
      end

      states = []
      %w{RUNNING STARTING FLAPPING DOWN}.each do |state|
        if (num = counts[state]) > 0
          states << "#{b(num)} #{c(for_output(state), state_color(state))}"
        end
      end

      total = instances.count
      running = counts["RUNNING"].to_s.rjust(total.to_s.size)

      ratio = "#{running}#{d(" of ")}#{total} instances running"
      line "#{ratio} (#{states.join(", ")})"
    end

    private
    def for_output(state)
      state = "CRASHING" if state == "FLAPPING"
      state.downcase
    end
  end
end
