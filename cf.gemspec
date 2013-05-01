# -*- encoding: utf-8 -*-

#############
# WARNING: Separate from the Gemfile. Please update both files
#############

$:.push File.expand_path("../lib", __FILE__)
require "cf/version"

Gem::Specification.new do |s|
  s.name        = "cf"
  s.version     = CF::VERSION.dup
  s.authors     = ["Cloud Foundry Team", "Alex Suraci"]
  s.email       = %w(vcap-dev@googlegroups.com)
  s.homepage    = "http://github.com/cloudfoundry/cf"
  s.summary     = %q{
    Friendly command-line interface for Cloud Foundry.
  }
  s.executables = %w{cf}

  s.rubyforge_project = "cf"

  s.files         = %w(LICENSE Rakefile) + Dir["lib/**/*"]
  s.test_files    = Dir["spec/**/*"]
  s.require_paths = %w(lib)

  s.add_runtime_dependency "addressable", "~> 2.2"
  s.add_runtime_dependency "caldecott-client", "~> 0.0.2"
  s.add_runtime_dependency "cfoundry", ">= 0.7.0.rc11", "< 0.8"
  s.add_runtime_dependency "interact", "~> 0.5"
  s.add_runtime_dependency "json_pure", "~> 1.6"
  s.add_runtime_dependency "mothership", ">= 0.5.1", "< 1.0"
  s.add_runtime_dependency "multi_json", "~> 1.3"
  s.add_runtime_dependency "rest-client", "~> 1.6"
  s.add_runtime_dependency "uuidtools", "~> 2.1"

  s.add_development_dependency "blue-shell", "= 0.0.3"
  s.add_development_dependency "fakefs", "~> 0.4.2"
  s.add_development_dependency "ffaker", "= 1.15"
  s.add_development_dependency "rake", "~> 0.9"
  s.add_development_dependency "rr", "~> 1.0"
  s.add_development_dependency "rspec", "~> 2.11"
  s.add_development_dependency "webmock", "~> 1.9"
  s.add_development_dependency "rspec-instafail", "~> 0.2.4"
end
