require "foobara/type/value_processor"

module Foobara
  class Type
    class ValueValidator < ValueProcessor
      class << self
        # This means we dont have to specify a symbol for it in the schema to activate it
        def always_applies?
          false
        end
      end

      attr_accessor :validator_data, :strict_schema_hash

      def initialize(validator_data, strict_schema_hash)
        super()
        self.validator_data = validator_data
        self.strict_schema_hash = strict_schema_hash
      end

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

      def build_error(
        value = nil,
        symbol: error_symbol,
        message: error_message(value),
        context: error_context(value),
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

      def error_symbol
        error_class.symbol
      end

      def error_path
        [attribute_name].compact
      end

      # TODO: this is a bit problematic. Maybe eliminate this instead of assuming it's generally useful
      def attribute_name
        nil
      end

      def error_message(_value)
        raise "subclass responsibility"
      end

      def error_context(_value)
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
