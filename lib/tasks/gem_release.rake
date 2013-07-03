require 'active_support/core_ext'

namespace :gem do
  desc "Bump gem version, push to RubyGems, push to Github, add release notes"
  task :release, [:version] do |_, args|
    version = args[:version] || 'rc'
    old_version = gem_version

    sh! "gem bump --version #{version} --no-commit"
    sh! "git add lib/cf/version.rb"

    print_with_purpose "Bumping to version #{gem_version}"
    generate_release_notes(old_version)
    sh!("git commit -m 'Bumping to version #{gem_version}.'")
    sh!("git push")
    sh!("gem release --tag")
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
end
