module FeaturesHelper
  def login
    set_target
    logout

    username = ENV['CF_V2_TEST_USER']
    password = ENV['CF_V2_TEST_PASSWORD']
    organization = ENV['CF_V2_TEST_ORGANIZATION']
    space = ENV['CF_V2_TEST_SPACE']

    cmd = "#{cf_bin} login #{username} --password #{password} -o #{organization}"
    cmd += " -s #{space}"
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
    target = ENV['CF_V2_TEST_TARGET']
    BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
      runner.wait_for_exit 20
    end
  end

  def create_service_instance(service_name, instance_name, opts = {})
    plan_name = opts[:plan]
    credentials = opts[:credentials]

    BlueShell::Runner.run("#{cf_bin} create-service") do |runner|
      expect(runner).to say "What kind?>"
      runner.send_keys service_name

      expect(runner).to say "Name?>"
      runner.send_keys instance_name

      if service_name == "user-provided"
        expect(runner).to say "What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)>"
        runner.send_keys credentials.keys.join(", ")

        credentials.each do |key, value|
          expect(runner).to say key.to_s
          runner.send_keys value.to_s
        end
      else
        expect(runner).to say "Which plan?"
        runner.send_keys plan_name
      end

      expect(runner).to say "Creating service #{instance_name}... OK"
    end
  end

  def push_app(app_folder, deployed_app_name, opts = {})
    push_cmd = "#{cf_bin} push --no-manifest"
    push_cmd += " --command #{opts[:start_command]}" if opts[:start_command]

    Dir.chdir("#{SPEC_ROOT}/assets/#{app_folder}") do
      BlueShell::Runner.run(push_cmd) do |runner|
        expect(runner).to say "Name>"
        runner.send_keys deployed_app_name

        expect(runner).to say "Instances> 1", 15
        runner.send_return

        expect(runner).to say "Memory Limit>"
        runner.send_keys "128M"

        expect(runner).to say "Creating #{deployed_app_name}... OK"

        expect(runner).to say "Subdomain> #{deployed_app_name}"
        runner.send_return

        expect(runner).to say "1:"
        expect(runner).to say "Domain>"
        runner.send_keys "1"

        expect(runner).to say /Creating route #{deployed_app_name}\..*\.\.\. OK/
        expect(runner).to say /Binding #{deployed_app_name}\..* to #{deployed_app_name}\.\.\. OK/

        expect(runner).to say "Create services for application?> n"
        runner.send_return

        if runner.expect "Bind other services to application?> n", 15
          runner.send_return
        end

        expect(runner).to say "Push successful!"

        runner.wait_for_exit opts[:timeout] || 30
      end
    end
  end
end
