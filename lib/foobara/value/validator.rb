module Foobara
  module Value
    class Validator < Processor
      def validation_errors(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process(value)
        return Outcome.success(value) unless applicable?(value)

        errors = validation_errors(value)

        if errors.blank?
          Outcome.success(value)
        else
          klass = error_halts_processing? ? HaltedOutcome : Outcome
          klass.new(errors:, result: value)
        end
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

      def possible_errors
        [
          [
            [],
            error_symbol,
            error_context_schema
          ]
        ]
      end
    end
  end
end
