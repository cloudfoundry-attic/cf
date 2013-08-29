require 'active_support/time'
require 'active_support/core_ext'

namespace :gem do
  desc "Bump gem version, push to RubyGems, push to Github, add release notes"
  task :release, [:version] do |_, args|
    version = args[:version] || 'rc'
    old_version = gem_version

    sh! "gem bump --version #{version} --no-commit"

    print "About to bump version to #{gem_version}, continue? (Y): "
    answer = STDIN.gets.strip
    exit unless answer.length == 0 || answer.upcase.start_with?("Y")

    sh! "git add lib/cf/version.rb"

    print_with_purpose "Bumping to version #{gem_version}"

    sh!("bundle")
    sh!("git add Gemfile.lock")

    generate_release_notes(old_version)

    sh!("git commit -m 'Bumping to version #{gem_version}.'")
    sh!("git push")
    sh!("gem release --tag")
    trigger_windows_executable_build
  end

  private

  def generate_release_notes(old_version)
    print_with_purpose "Generating release notes..."
    file_name = "release_#{gem_version}"
    sh!("anchorman notes --name=#{file_name} --from=v#{old_version}")
    sh!("git add release_notes")
  end

  def sh!(cmd)
    `#{cmd}`
    raise "borked with #{$?}" unless $?.success?
  end

  def print_with_purpose(text)
    puts "\033[34m#{text}\033[0m"
  end

  def gem_version
    silence_warnings do
      load "lib/cf/version.rb"
    end
    Gem::Specification.load("cf.gemspec").version.to_s
  end

  def trigger_windows_executable_build
    sh!("url -X POST https://frontend-jenkins.cf-app.com/job/CLI-Windows-Build/build -u ci:clone7adhere --insecure")
  end
end
