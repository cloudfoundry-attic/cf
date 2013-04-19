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
    BlueShell::Runner.run("#{cf_bin} logout")
  end

  def set_target
    BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
      runner.wait_for_exit(20)
    end
  end
end
