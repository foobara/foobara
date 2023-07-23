module Foobara
  class Type
    class Caster
      attr_accessor :type_symbol

      def initialize(type_symbol: nil)
        self.type_symbol = type_symbol
      end
    end
  end
end
