module Foobara
  class Type
    class ValueProcessor
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
