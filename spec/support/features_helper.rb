module FeaturesHelper
  def login
    set_target
    logout

    space = ENV['CF_V2_TEST_SPACE']
    organization = ENV['CF_V2_TEST_ORGANIZATION']
    username = ENV['CF_V2_TEST_USER']
    password = ENV['CF_V2_TEST_PASSWORD']

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
      runner.wait_for_exit(20)
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
        credentials.keys.each_with_index do |k, i|
          expect(runner).to say "Key"
          runner.send_keys k
          expect(runner).to say "Value"
          runner.send_keys credentials[k]
          expect(runner).to say "Another credentials parameter?"
          if i < credentials.size - 1
            runner.send_keys "y"
          else
            runner.send_keys "n"
          end
        end
      else
        expect(runner).to say "Which plan?"
        runner.send_keys plan_name
      end

      expect(runner).to say "Creating service #{instance_name}... OK"
    end
  end

  def push_app(app_folder, deployed_app_name)
    Dir.chdir("#{SPEC_ROOT}/assets/#{app_folder}") do
      BlueShell::Runner.run("#{cf_bin} push --no-manifest") do |runner|
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
