class Object
  def try(*args)
    send(*args)
  end
end

class NilClass
  def try(*args)
    nil
  end
end