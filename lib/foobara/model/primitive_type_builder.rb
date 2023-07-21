module Foobara
  class Model
    class PrimitiveTypeBuilder < TypeBuilder
      attr_accessor :symbol

      def initialize(symbol)
        self.symbol = symbol
        super()
      end
    end
  end
end
