class MockStartCommand
  attr_reader :started_apps
  attr_accessor :input

  def initialize
    @started_apps = []
  end

  def start
    raise 'If you wanna test using :all, you implement it!' if input[:all]
    @started_apps = input[:apps]
  end

  def run(_)
    start
  end
end
