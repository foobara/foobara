require "foobara/type/value_processor"

module Foobara
  class Type
    class ValueTransformer < ValueProcessor
      def transform(_value)
        raise "subclass responsibility"
      end

      def process(outcome)
        outcome.result = transform(outcome.result)
      end
    end
  end
end
