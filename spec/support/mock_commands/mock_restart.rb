class MockRestartCommand
  attr_reader :restarted_apps
  attr_accessor :input

  def initialize
    @restarted_apps = []
  end

  def restart
    @restarted_apps = input[:apps]
  end

  def run(_)
    restart
  end
end
