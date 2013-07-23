RSpec::Matchers.define :has_label do |expected|
  match do |actual|
    actual.label == expected
  end
end
