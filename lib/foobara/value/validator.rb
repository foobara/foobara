module Foobara
  module Value
    class Validator < Processor
      class Runner < Processor::Runner
        runner_methods :validation_errors
      end

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
        **
      )
        error_class.new(
          path:,
          message:,
          context:,
          **
        )
      end

      def possible_errors
        [
          [
            [],
            error_symbol,
            error_class
          ]
        ]
      end
    end
  end
end
