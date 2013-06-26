require "cf/cli"

module CFAdmin
  class Guid < CF::CLI
    def precondition
      check_target
    end

    desc "Obtain guid of an object(s)"
    group :admin
    input :type, :argument => :required, :desc => "Object type (e.g. org, space, app, domain, ...)"
    input :name, :argument => :optional, :desc => "Object name (e.g. some-app, ...)"
    def guid
      type = expand_type(input[:type])
      name = input[:name]

      _, res = client.base.rest_client.request("GET", api_path(type, name))

      puts "Listing #{type} for '#{name}'...\n\n"
      puts_response(res[:body])
    end

    private

    def api_path(type, name)
      "".tap do |url|
        url << "v2/#{type}?"
        url << "q=name:#{name}" if name
      end
    end

    EXPANDED_TYPES = %w(
      organizations
      spaces
      domains
      routes
      apps
      services
      service_instances
      users
    )

    def expand_type(type)
      EXPANDED_TYPES.detect do |expanded_type|
        expanded_type.start_with?(type)
      end || type
    end

    def puts_response(body)
      # passing nil to load causes segfault
      hash = MultiJson.load(body || "{}") rescue {}

      puts_pagination(*hash.values_at("total_results", "total_pages"))
      puts_resources(hash["resources"])
    end

    def puts_pagination(results, pages)
      if results.nil?
        puts "Unexpected response."
      elsif results == 0
        puts "No results."
      else
        puts "Found #{results} results on #{pages} pages. First page:"
      end
    end

    def puts_resources(resources)
      resources ||= []

      sorted_resources = \
        resources.sort_by { |r| [r["entity"]["name"].downcase] }

      max_name_size = \
        resources.map { |r| r["entity"]["name"].size }.max

      sorted_resources.each_with_index do |resource, i|
        puts_resource(resource, :max_name_size => max_name_size)
        puts "---" if i % 3 == 2
      end
    end

    def puts_resource(resource, opts={})
      puts [
        resource["entity"]["name"].ljust(opts[:max_name_size] + 2),
        resource["metadata"]["guid"],
      ].join
    end
  end
end
