module Rfm::Util # :nodoc: all
  class CaseInsensitiveHash < Hash
    def []=(key, value)
      super(key.downcase, value)
    end
    def [](key)
      super(key.downcase)
    end
  end
end