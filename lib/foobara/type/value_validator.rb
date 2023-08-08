require "foobara/type/value_transformer"

module Foobara
  class Type
    class ValueValidator < ValueTransformer
      class << self
        def error_class
          return @error_class if defined?(@error_class)

          unless error_classes.size == 1
            raise "Expected exactly one error class to be defined for #{name} but has #{error_classes.size}"
          end

          @error_class = error_classes.first
        end

        def error_classes
          @error_classes ||= Util.constant_values(self, extends: Foobara::Error)
        end

        def error_symbol
          error_class.symbol
        end

        def error_message(value)
          error_class.message(value)
        end

        def error_context(_value)
          error_class.context(value)
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

      delegate :error_class,
               :error_symbol,
               :error_message,
               :error_context,
               :error_context_schema,
               to: :class

      delegate :symbol, to: :class

      # Can we eliminate this path parameter???
      def call(_value, _path)
        raise "subclass responsibility"
      end

      def build_error(
        value = nil,
        message: error_message(value),
        context: error_context(value),
        path: error_path,
        **args
      )
        error_class.new(
          path:,
          message:,
          context:,
          **args
        )
      end

      def error_path
        [attribute_name].compact
      end

      # TODO: this is a bit problematic. Maybe eliminate this instead of assuming it's generally useful
      def attribute_name
        nil
      end

      def error_halts_processing?
        false
      end
    end
  end
end
