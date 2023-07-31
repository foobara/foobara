require "foobara/type/value_processor"

module Foobara
  class Type
    class ValueValidator < ValueProcessor
      def validation_errors(_value)
        raise "subclass responsibility"
      end

      def process_outcome(outcome, path)
        errors = validation_errors(outcome.result)

        Array.wrap(errors).each do |error|
          error.path = [*path, *error.path]
          outcome.add_error(error)
        end
      end

      def error_class
        Util.constant_value(self.class, :Error)
      end

      def build_error(message: error_message, context: error_context, path: error_path, **args)
        error_class.new(
          path:,
          message:,
          context:,
          **args
        )
      end

      def error_symbol
        error_class.symbol
      end

      def error_path
        []
      end

      def attribute_name
        nil
      end

      def error_message
        raise "subclass responsibility"
      end

      def error_context
        raise "subclass responsibility"
      end

      # TODO: this is a problem or an indicator we need to couple Type and Schema.
      # here we are in the Type namespace but we really need to communicate the error context schemas to the
      # outside world for things like Schema and Command to work well.
      # A solution... a way to map built-in validator errors to schemas a level up in Schema.
      # Not necessary but maybe a good idea just to preserve separation of concerns for longer
      def error_context_schema
        error_class.context_schema
      end
    end
  end
end
