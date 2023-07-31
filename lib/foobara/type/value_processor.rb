module Foobara
  class Type
    class ValueProcessor
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
