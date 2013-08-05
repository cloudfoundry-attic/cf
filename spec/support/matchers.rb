class HasLabelMatcher
  def initialize(expected_label)
    @expected = expected_label
  end
  def failure_message_for_should
    "#{actual} does not have label #{@expected}"
  end
  def ==(actual)
    actual.label == @expected
  end
  alias_method :matches?, :==
end

def has_label(expected_label)
  HasLabelMatcher.new(expected_label)
end
