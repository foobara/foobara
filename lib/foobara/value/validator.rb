module Foobara
  module Value
    class Validator < Processor
      def validation_errors(_value)
        raise "subclass responsibility"
      end

      def process(value)
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
    end
  end
end
