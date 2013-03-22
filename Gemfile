source "http://rubygems.org"

#############
# WARNING: Separate from the Gemspec. Please update both files
#############

gem "json_pure", "~> 1.6"
gem "multi_json", "~> 1.3"
gem "rake"

gem "interact", :git => "git://github.com/vito/interact.git"
gem "cfoundry", :git => "git://github.com/cloudfoundry/cfoundry.git", :submodules => true
gem "mothership", :git => "git://github.com/vito/mothership.git"

gem "admin-cf-plugin", :git => "git://github.com/cloudfoundry/admin-cf-plugin.git"
gem "console-cf-plugin", :git => "git://github.com/cloudfoundry/console-cf-plugin.git"
gem "micro-cf-plugin", :git => "git://github.com/cloudfoundry/micro-cf-plugin.git"
gem "manifests-cf-plugin", :git => "git://github.com/cloudfoundry/manifests-cf-plugin.git"
gem "tunnel-cf-plugin", :git => "git://github.com/cloudfoundry/tunnel-cf-plugin.git"

group :test do
  gem "rspec", "~> 2.11"
  gem "webmock", "~> 1.9"
  gem "rr", "~> 1.0"
  gem "ffaker"
  gem "fakefs"
  gem "parallel_tests"
end

group :development do
  gem "gem-release"
end
