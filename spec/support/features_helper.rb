module FeaturesHelper
  def login
    logout
    set_target

    BlueShell::Runner.run("#{cf_bin} login #{username} --password #{password}") do |runner|
      expect(runner).to say(
        "Organization>" => proc {
          runner.send_keys organization
          expect(runner).to say /Switching to organization .*\.\.\. OK/
        },
        "Switching to organization" => proc {}
      )

      expect(runner).to say(
        "Space>" => proc {
          runner.send_keys "1"
          expect(runner).to say /Switching to space .*\.\.\. OK/
        },
        "Switching to space" => proc {}
      )
    end
  end

  def logout
    BlueShell::Runner.run("#{cf_bin} logout")
  end

  def set_target
    BlueShell::Runner.run("#{cf_bin} target #{target}")
  end
end
