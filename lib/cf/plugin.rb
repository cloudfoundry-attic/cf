require "set"
require "yaml"

require "cf/constants"
require "cf/cli"

module CF
  module Plugin
    @@plugins = []

    def self.load_all
      # auto-load gems with 'cf-plugin' in their name
      matching =
        if Gem::Specification.respond_to? :find_all
          Gem::Specification.find_all do |s|
            s.name =~ /cf-plugin/
          end
        else
          Gem.source_index.find_name(/cf-plugin/)
        end

      enabled = Set.new(matching.collect(&:name))

      cf_gems = Gem.loaded_specs["cf"]
      ((cf_gems && cf_gems.dependencies) || Gem.loaded_specs.values).each do |dep|
        if dep.name =~ /cf-plugin/
          require "#{dep.name}/plugin"
          enabled.delete dep.name
        end
      end

      # allow explicit enabling/disabling of gems via config
      plugins = File.expand_path(CF::PLUGINS_FILE)
      if File.exists?(plugins) && yaml = YAML.load_file(plugins)
        enabled += yaml["enabled"] if yaml["enabled"]
        enabled -= yaml["disabled"] if yaml["disabled"]
      end

      # load up each gem's 'plugin' file
      #
      # we require this file specifically so people can require the gem
      # without it plugging into CF
      enabled.each do |gemname|
        begin
          require "#{gemname}/plugin"
        rescue Gem::LoadError => e
          puts "Failed to load #{gemname}:"
          puts "  #{e}"
          puts
          puts "You may need to update or remove this plugin."
          puts
        end
      end
    end
  end
end
