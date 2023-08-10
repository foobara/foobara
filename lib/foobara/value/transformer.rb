require "foobara/value/processor"

module Foobara
  module Value
    class Transformer < Processor
      def transform(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process(value)
        return Outcome.success(value) unless applicable?(value)

        Outcome.success(transform(value))
      end

      def possible_errors
        []
      end
    end
  end
end
