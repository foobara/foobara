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
        if applicable?(value)
          value = transform(value)
        end

        Outcome.success(value)
      end

      def possible_errors
        []
      end
    end
  end
end
