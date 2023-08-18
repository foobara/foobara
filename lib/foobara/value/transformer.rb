require "foobara/value/processor"

module Foobara
  module Value
    class Transformer < Processor
      class << self
        def error_classes
          []
        end
      end

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
    end
  end
end
