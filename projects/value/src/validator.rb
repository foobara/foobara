module Foobara
  module Value
    class Validator < Processor
      class Runner < Processor::Runner
        runner_methods :validation_errors
      end

      class << self
        def foobara_manifest(to_include:)
          super.merge(processor_type: :transformer)
        end
      end

      # Should a Validator only return one type of error?
      def validation_errors(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process_value(value)
        return Outcome.success(value) unless applicable?(value)

        errors = Util.array(validation_errors(value))

        if errors.empty?
          Outcome.success(value)
        else
          Outcome.new(errors:, result: value)
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
        key = ErrorKey.new(symbol: error_symbol, category: error_class.category)

        { key.to_sym => error_class }
      end
    end
  end
end
