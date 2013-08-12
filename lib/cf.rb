require "cf/version"

require "cf/cli"

command_files = "../cf/cli/{app,route,domain,organization,space,service,start,user}/*.rb"
Dir[File.expand_path(command_files, __FILE__)].each do |file|
  require file unless File.basename(file) == 'base.rb'
end

require "manifests/plugin"
require "admin/plugin"
require "console/plugin"
require "tunnel/plugin"
require "micro/plugin"
