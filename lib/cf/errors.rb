module CF
  class UserFriendlyError < RuntimeError
    def initialize(msg)
      @message = msg
    end

    def to_s
      @message
    end
  end

  class UserFriendlyErrorWithDetails < RuntimeError
    attr_reader :original

    def initialize(msg, original)
      @message = msg
      @original = original
    end

    def to_s
      @message
    end
  end

  class UserError < UserFriendlyError; end

  class NotAuthorized < UserError
    def initialize
      @message = "Not authorized."
    end
  end
end
