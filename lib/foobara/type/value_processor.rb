module Foobara
  class Type
    class ValueProcessor
      attr_accessor :type_symbol

      def initialize(type_symbol: nil)
        # TODO: eliminate this type symbol thingy. Shouldn't be needed.
        self.type_symbol = type_symbol || :custom
      end

      def applicable?(_value)
        true
      end

      def process_outcome(_outcome, _path)
        raise "subclass responsibility"
      end

      def error_halts_processing?
        false
      end

      def halt_if_already_not_success?
        false
      end
    end
  end
end
