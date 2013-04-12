module FeaturesHelper
  def login
    set_target
    logout

    cmd = "yes 1 | #{cf_bin} login #{username} --password #{password} -o #{organization}"
    cmd += " -s #{space}" if respond_to?(:space)
    BlueShell::Runner.run(cmd) do |runner|
      runner.wait_for_exit 30
    end
  end

  def logout
    BlueShell::Runner.run("#{cf_bin} logout")
  end

  def set_target
    BlueShell::Runner.run("#{cf_bin} target #{target}")
  end
end
