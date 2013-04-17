require "spec_helper"

describe CFManifests::Builder do
  subject { CFManifests::Loader.new(nil, nil) }

  describe "#build" do
    let(:file) { "manifest.yml" }

    before do
      FakeFS.activate!

      File.open(file, "w") do |io|
        io.write manifest
      end
    end

    after do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear
    end

    context "with a simple manifest" do
      let(:manifest) do
        <<EOF
---
foo: bar
EOF
      end

      it "loads the manifest YAML" do
        expect(subject.build(file)).to eq("foo" => "bar")
      end
    end

    context "with a manifest that inherits another" do
      let(:manifest) do
        <<EOF
---
inherit: other-manifest.yml
foo:
  baz: c
EOF
      end

      before do
        FakeFS.activate!

        File.open("other-manifest.yml", "w") do |io|
          io.write <<OTHER
---
foo:
  bar: a
  baz: b
OTHER
        end
      end

      it "merges itself into the parent, by depth" do
        manifest = subject.build(file)
        expect(manifest).to include(
          "foo" => { "bar" => "a", "baz" => "c" })
      end

      it "does not include the 'inherit' attribute" do
        manifest = subject.build(file)
        expect(manifest).to_not include("inherit")
      end
    end

    context "with an invalid manifest" do
      let(:manifest) { "" }

      it "raises an error" do
        expect {
          subject.build(file)
        }.to raise_error(CFManifests::InvalidManifest)
      end
    end
  end
end
