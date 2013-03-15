SPEC_ROOT = File.dirname(__FILE__).freeze

require "rspec"
require "cfoundry"
require "cfoundry/test_support"
require "cf"
require "cf/test_support"
require "webmock"
require "ostruct"
require "fakefs/safe"

INTEGRATE_WITH = ENV["INTEGRATE_WITH"] || "default"
TRAVIS_BUILD_ID = ENV["TRAVIS_BUILD_ID"]

OriginalFile = File

class FakeFS::File
  def self.fnmatch(*args, &blk)
    OriginalFile.fnmatch(*args, &blk)
  end
end

def cf_bin
  cf = File.expand_path("#{SPEC_ROOT}/../bin/cf.dev")
  if INTEGRATE_WITH != 'default'
    "rvm #{INTEGRATE_WITH}@cf do #{cf}"
  else
    cf
  end
end

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each do |file|
  require file
end

RSpec.configure do |c|
  c.include Fake::FakeMethods
  c.include ConsoleAppSpeckerMatchers

  c.mock_with :rr

  if RUBY_VERSION =~ /^1\.8\.\d/
    c.filter_run_excluding :ruby19 => true
  end

  c.include FakeHomeDir
  c.include CommandHelper
  c.include InteractHelper
  c.include ConfigHelper

  c.before(:all) do
    WebMock.disable_net_connect!
  end

  c.before do
    CF::CLI.send(:class_variable_set, :@@client, nil)
  end
end

def name_list(xs)
  if xs.empty?
    "none"
  else
    xs.collect(&:name).join(", ")
  end
end

def run(command)
  SpeckerRunner.new(command) do |runner|
    yield runner
  end
end
