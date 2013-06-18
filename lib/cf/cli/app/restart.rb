require "cf/cli/app/base"

module CF::App
  class Restart < Base
    desc "Stop and start an application"
    group :apps, :manage
    input :apps, :desc => "Applications to start", :argument => :splat,
          :singular => :app, :from_given => by_name(:app)
    input :debug_mode, :desc => "Debug mode to start in", :aliases => "-d"
    input :all, :desc => "Restart all applications", :default => false

    ############# Uncomment to complete 50543607
    #input :command, :desc => "Command to restart application", :default => nil

    def restart
      invoke :stop, :all => input[:all], :apps => input[:apps]

      line unless quiet?

      input[:apps].each do |app|
        unless input[:command].nil?
          app.command = input[:command]
        end
        app.update!
      end

      invoke :start, :all => input[:all], :apps => input[:apps],
        :debug_mode => input[:debug_mode]
    end
  end
end
