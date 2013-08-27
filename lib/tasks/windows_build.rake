namespace :windows do
  desc "Create a Windows .exe file"
  task :build, [:version] do |_, args|
    system("ocra --console --no-autoload bin/cf")
  end
end
