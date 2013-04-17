require "manifests/errors"

module CFManifests
  module Builder
    # parse a manifest and merge with its inherited manifests
    def build(file)
      manifest = YAML.load_file file
      raise CFManifests::InvalidManifest.new(file) unless manifest

      Array(manifest["inherit"]).each do |path|
        manifest = merge_parent(path, manifest)
      end

      manifest.delete("inherit")

      manifest
    end

    private

    # merge the manifest at `parent_path' into the `child'
    def merge_parent(parent_path, child)
      merge_manifest(build(from_manifest(parent_path)), child)
    end

    # deep hash merge
    def merge_manifest(parent, child)
      merge = proc do |_, old, new|
        if new.is_a?(Hash) && old.is_a?(Hash)
          old.merge(new, &merge)
        else
          new
        end
      end

      parent.merge(child, &merge)
    end
  end
end
