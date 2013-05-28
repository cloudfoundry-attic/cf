module FeaturesHelper
  def login
    set_target
    logout

    to_space = respond_to?(:space) ? space : ENV['CF_V2_TEST_SPACE']

    cmd = "#{cf_bin} login #{username} --password #{password} -o #{organization}"
    cmd += " -s #{to_space}"
    BlueShell::Runner.run(cmd) do |runner|
      runner.wait_for_exit 60
    end
  end

  def logout
    BlueShell::Runner.run("#{cf_bin} logout") do |runner|
      runner.wait_for_exit 60
    end
  end

  def set_target
    BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
      runner.wait_for_exit(20)
    end
  end

  def push_app(app_folder, deployed_app_name)
    Dir.chdir("#{SPEC_ROOT}/assets/#{app_folder}") do
      BlueShell::Runner.run("#{cf_bin} push --no-manifest") do |runner|
        expect(runner).to say "Name>"
        runner.send_keys deployed_app_name

        expect(runner).to say "Instances> 1", 15
        runner.send_return

        expect(runner).to say "Custom startup command> "
        runner.send_return

        expect(runner).to say "Memory Limit>"
        runner.send_keys "128M"

        expect(runner).to say "Creating #{deployed_app_name}... OK"

        expect(runner).to say "Subdomain> #{deployed_app_name}"
        runner.send_return

        expect(runner).to say "1:"
        expect(runner).to say "Domain>"
        runner.send_keys "1"

        expect(runner).to say(/Creating route #{deployed_app_name}\..*\.\.\. OK/)
        expect(runner).to say(/Binding #{deployed_app_name}\..* to #{deployed_app_name}\.\.\. OK/)

        expect(runner).to say "Create services for application?> n"
        runner.send_return

        if runner.expect "Bind other services to application?> n", 15
          runner.send_return
        end

        runner.wait_for_exit
      end
    end
  end
end
