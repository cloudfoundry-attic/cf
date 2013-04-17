require "spec_helper"

describe CFManifests::InvalidManifest do
  let(:file) { "/path/to/file" }

  subject { described_class.new(file) }

  it { should be_kind_of CF::UserFriendlyError }

  describe "#initialize" do
    it "is initialized with a file" do
      described_class.new(file)
    end
  end

  describe "#to_s" do
    it "says the file is malformed" do
      expect(subject.to_s).to eq(
        "Manifest file '#{file}' is malformed.")
    end
  end

  describe "#file" do
    it "returns the file it was initialized with" do
      expect(subject.file).to eq(file)
    end
  end
end

describe CFManifests::CircularDependency do
  let(:app) { "app" }
  subject { described_class.new(app) }

  it { should be_kind_of CF::UserFriendlyError }
end

describe CFManifests::UnknownSymbol do
  let(:symbol) { "symbol" }
  subject { described_class.new(symbol) }

  it { should be_kind_of CF::UserFriendlyError }
end

