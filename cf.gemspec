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

  s.add_runtime_dependency "json_pure", "~> 1.6"
  s.add_runtime_dependency "multi_json", "~> 1.3"

  s.add_runtime_dependency "interact", "~> 0.5"
  s.add_runtime_dependency "cfoundry", "~> 0.6.0"
  s.add_runtime_dependency "mothership", ">= 0.5.1", "< 1.0"
  s.add_runtime_dependency "manifests-cf-plugin", ">= 0.7.0.rc6", "< 0.8"
  s.add_runtime_dependency "tunnel-cf-plugin", "~> 0.3.0"

  s.add_development_dependency "rake", "~> 0.9"
  s.add_development_dependency "rspec", "~> 2.11"
  s.add_development_dependency "webmock", "~> 1.9"
  s.add_development_dependency "rr", "~> 1.0"
end
