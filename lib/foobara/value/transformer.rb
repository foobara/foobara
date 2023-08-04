require "foobara/value/processor"

module Foobara
  module Value
    class Transformer < Processor
      class << self
        def primary_proc_method
          :transform
        end

        def error_class
          raise "Do not build errors in transformers. Use a Validator instead."
        end
      end

      def transform(_value)
        raise "subclass responsibility"
      end

      def call(value)
        Outcome.success(transform(value))
      end
    end
  end
end
