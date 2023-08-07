require "foobara/type/value_processor"

module Foobara
  class Type
    class ValueTransformer < ValueProcessor
      def transformer_data
        processor_data
      end

      def transform(_value)
        raise "subclass responsibility"
      end

      def process_outcome(outcome, _path)
        outcome.result = transform(outcome.result)
      end
    end
  end
end
