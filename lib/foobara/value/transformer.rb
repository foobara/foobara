require "foobara/value/processor"
require "foobara/value/processor/runner"

module Foobara
  module Value
    class Transformer < Processor
      class Runner < Processor::Runner
        runner_methods :transform
      end

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
