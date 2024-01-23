module Foobara
  class PossibleError
    attr_accessor :key, :error_class, :data

    def initialize(error_class, key: nil, data: nil, symbol: error_class.symbol, category: error_class.category)
      self.error_class = error_class
      self.data = data
      self.key = if key
                   if key.is_a?(ErrorKey)
                     key
                   else
                     ErrorKey.parse(key)
                   end
                 else
                   ErrorKey.new(symbol:, category:)
                 end
    end

    def dup
      PossibleError.new(
        error_class,
        key: key.dup,
        data:
      )
    end

    def prepend_path!(...)
      key.prepend_path!(...)
    end

    def prepend_runtime_path!(...)
      key.prepend_runtime_path!(...)
    end
  end
end
