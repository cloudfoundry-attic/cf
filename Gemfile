source "http://rubygems.org"

#############
# WARNING: Separate from the Gemspec. Please update both files
#############

gemspec

gem "json_pure", "~> 1.6"
gem "multi_json", "~> 1.3"
gem "rake"

gem "cfoundry", :git => "git://github.com/cloudfoundry/cfoundry.git", :submodules => true
gem "interact", :git => "git://github.com/vito/interact.git"

gem "mothership", :git => "git://github.com/vito/mothership.git"

gem "admin-cf-plugin", :git => "git://github.com/cloudfoundry/admin-cf-plugin.git"
gem "manifests-cf-plugin", :git => "git://github.com/cloudfoundry/manifests-cf-plugin.git"
gem "micro-cf-plugin", :git => "git://github.com/cloudfoundry/micro-cf-plugin.git"

group :test do
  gem "blue-shell", ">= 0.0.3", :git => "git://github.com/pivotal/blue-shell.git"
  gem "fakefs"
  gem "ffaker"
  gem "parallel_tests"
  gem "rr", "~> 1.0"
  gem "rspec", "~> 2.11"
  gem "webmock", "~> 1.9"
end

group :development do
  gem "auto_tagger"
  gem "gem-release"
  gem "gerrit-cli"
end
