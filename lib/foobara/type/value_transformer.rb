require "foobara/type/value_processor"

module Foobara
  class Type
    class ValueTransformer < ValueProcessor
      def transform(_value)
        raise "subclass responsibility"
      end
    end
  end
end
