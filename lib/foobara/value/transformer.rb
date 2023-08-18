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

      def method_missing(method, *args, **opts)
        method == symbol ? declaration_data : super
      end

      def respond_to_missing?(method, private = false)
        method == symbol || super
      end
    end
  end
end
