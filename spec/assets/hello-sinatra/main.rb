require "rubygems"
require "sinatra"

class Main < Sinatra::Base
	get "/" do
	  "Hello, world!"
	end
end
