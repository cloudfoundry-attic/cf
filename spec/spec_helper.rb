SPEC_ROOT = File.dirname(__FILE__).freeze

require "rspec"
require "cfoundry"
require "cfoundry/test_support"
require "cf"
require "cf/test_support"
require "webmock"
require "webmock/rspec"
require "ostruct"
require "fakefs/safe"
require "blue-shell"

Dir.glob("support/mock_commands/*").each { |f| require f }

TRAVIS_BUILD_ID = ENV["TRAVIS_BUILD_ID"]

OriginalFile = File

class FakeFS::File
  def self.fnmatch(*args, &blk)
    OriginalFile.fnmatch(*args, &blk)
  end
end

def cf_bin
  File.expand_path("#{SPEC_ROOT}/../bin/cf.dev")
end

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each do |file|
  require file
end

RSpec.configure do |c|
  c.include BlueShell::Matchers

  if RUBY_VERSION =~ /^1\.8\.\d/
    c.filter_run_excluding :ruby19 => true
  end

  c.include FakeHomeDir
  c.include CliHelper
  c.include InteractHelper
  c.include ConfigHelper
  c.include FeaturesHelper

  c.before(:all) do
    WebMock.disable_net_connect!(:allow_localhost => true)
  end

  c.before do
    CF::CLI.send(:class_variable_set, :@@client, nil)
  end

  c.after do
    if example.exception != nil && example.exception.message.include?("~/.cf/crash")
      puts '~/.cf/crash output for failed spec:'
      puts `cat ~/.cf/crash`
    end
  end
end

def name_list(xs)
  if xs.empty?
    "none"
  else
    xs.collect(&:name).join(", ")
  end
end
