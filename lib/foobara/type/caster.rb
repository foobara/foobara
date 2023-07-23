module Foobara
  class Type
    class Caster
      attr_accessor :type_symbol

      def initialize(type_symbol: nil)
        self.type_symbol = type_symbol
      end

      def applicable?
        raise "subclass responsibility"
      end

      def cast_from(value)
        raise "subclass responsibility"
      end
    end
  end
end
