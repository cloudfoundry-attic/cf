class Object
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end
end

class NilClass
  def try(*a, &b)
    nil
  end
end