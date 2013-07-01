require 'find'
require "micro/errors"

module CFMicro
  def config_file(file)
    File.expand_path("../../../../config/#{file}", __FILE__)
  end

  def escape_path(path)
    path = File.expand_path(path)
    if RUBY_PLATFORM =~ /mingw|mswin32|cygwin/
      if path.include?(' ')
        '"' + path + '"'
      else
        path
      end
    else
      path.gsub(' ', '\ ')
    end
  end

  def locate_file(file, directory, search_paths)
    search_paths.each do |path|
      expanded_path = File.expand_path(path)
      next unless File.exists?(expanded_path)
      Find.find(expanded_path) do |current|
        if File.directory?(current) && current.include?(directory)
          full_path = File.join(current, file)
          return escape_path(full_path) if File.exists?(full_path)
        end
      end
    end

    false
  end

  def run_command(command, args=nil)
    # TODO switch to using posix-spawn instead
    result = %x{#{command} #{args} 2>&1}
    if $?.exitstatus == 0
      result.split(/\n/)
    else
      if block_given?
        yield
      else
        raise CFMicro::MCFError, "failed to execute #{command} #{args}:\n#{result}"
      end
    end
  end

  module_function :config_file
  module_function :escape_path
  module_function :locate_file
  module_function :run_command

end
