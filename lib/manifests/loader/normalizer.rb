module CFManifests
  module Normalizer
    MANIFEST_META = ["applications", "properties"]

    def normalize!(manifest)
      toplevel = toplevel_attributes(manifest)

      apps = manifest["applications"]
      apps ||= [{}]

      default_paths_to_keys!(apps)

      apps = convert_to_array(apps)

      merge_toplevel!(toplevel, manifest, apps)
      normalize_apps!(apps)

      manifest["applications"] = apps

      normalize_paths!(apps)

      keyval = normalize_key_val(manifest)
      manifest.clear.merge!(keyval)

      nil
    end

    private

    def normalize_paths!(apps)
      apps.each do |app|
        app["path"] = from_manifest(app["path"])
      end
    end

    def convert_to_array(apps)
      return apps if apps.is_a?(Array)

      ordered_by_deps(apps)
    end

    # sort applications in dependency order
    # e.g. if A depends on B, B will be listed before A
    def ordered_by_deps(apps, processed = Set[])
      ordered = []
      apps.each do |tag, info|
        next if processed.include?(tag)

        if deps = Array(info["depends-on"])
          dep_apps = {}
          deps.each do |dep|
            dep_apps[dep] = apps[dep]
          end

          processed.add(tag)

          ordered += ordered_by_deps(dep_apps, processed)
          ordered << info
        else
          ordered << info
          processed.add(tag)
        end
      end

      ordered.each { |app| app.delete("depends-on") }

      ordered
    end

    def default_paths_to_keys!(apps)
      return if apps.is_a?(Array)

      apps.each do |tag, app|
        app["path"] ||= tag
      end
    end

    def normalize_apps!(apps)
      apps.each do |app|
        normalize_app!(app)
      end
    end

    def merge_toplevel!(toplevel, manifest, apps)
      return if toplevel.empty?

      apps.collect! do |a|
        toplevel.merge(a)
      end

      toplevel.each do |k, _|
        manifest.delete k
      end
    end

    def normalize_app!(app)
      if app.key?("mem")
        app["memory"] = app.delete("mem")
      end

      if app.key?("url") && app["url"].nil?
        app["url"] = "none"
      end

      if app.key?("subdomain")
        if app.key?("host")
          app.delete("subdomain")
        else
          app["host"] = app.delete("subdomain")
        end
      end
    end

    def toplevel_attributes(manifest)
      top =
        manifest.reject { |k, _|
          MANIFEST_META.include? k
        }

      # implicit toplevel path of .
      top["path"] ||= "."

      top
    end

    def normalize_key_val(val)
      case val
      when Hash
        stringified = {}

        val.each do |k, v|
          stringified[k.to_sym] = normalize_key_val(v)
        end

        stringified
      when Array
        val.collect { |x| normalize_key_val(x) }
      when nil
        nil
      else
        val.to_s
      end
    end
  end
end
