require "foobara/value/processor"

module Foobara
  module Value
    class Transformer < Processor
      def transform(_value)
        raise "subclass responsibility"
      end

      def process(value)
        Outcome.success(transform(value))
      end
    end
  end
end
