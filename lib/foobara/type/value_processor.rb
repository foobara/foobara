module Foobara
  class Type
    class ValueProcessor
      attr_accessor :type_symbol

      def initialize(type_symbol: nil)
        self.type_symbol = type_symbol || :custom
      end

      def applicable?(_value)
        true
      end

      def process(_value)
        raise "subclass responsibility"
      end

      def error_halts_processing?
        false
      end
    end
  end
end
