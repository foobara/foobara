module Foobara
  module Value
    class Value::Processor < Value::Validator
      delegate :error_classes, to: :class

      def call(_value)
        raise "subclass responsibility"
      end

      def build_error(
        error_class = self.class.error_class,
        value = nil,
        symbol: error_class.error_symbol,
        message: error_class.error_message(value),
        context: error_class.error_context(value),
        path: error_path,
        **args
      )
        error_class.new(
          path:,
          message:,
          context:,
          symbol:,
          **args
        )
      end
    end
  end
end
