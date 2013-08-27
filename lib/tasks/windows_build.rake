# In order for this to work you'll need to install the following on the Windows box:
#  git
#  RubyInstaller (1.9.3)
#  DevKit from RubyInstaller (tdm 32-bit to match 1.9.3)
#
#  gem install bundler
#  bundle
#  rake windows:build
namespace :windows do
  desc "Create a Windows .exe file"
  task :build do
    system("ocra --console --no-autoload bin/cf")
  end
end
