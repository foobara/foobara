module Foobara
  module Value
    module MultiProcessor
      attr_accessor :processors

      def initialize(*args, processors:)
        self.processors = processors
        super(*args)
      end

      def error_classes
        processors.map(&:error_classes)
      end

      # TODO: can we get away with overriding process instead?
      def process_outcome(old_outcome)
        return old_outcome unless applicable?(old_outcome.result)
        return old_outcome if old_outcome.is_a?(Value::HaltedOutcome)

        processors.inject(old_outcome) do |outcome, processor|
          processor.process_outcome(outcome)
        end
      end

      def process(value)
        process_outcome(Outcome.success(value))
      end

      def applicable?(value)
        processors.any? { |processor| processor.applicable?(value) }
      end

      # format?
      # maybe [path, symbol, context_type] ?
      # maybe [path, error_class] ?
      def possible_errors
        processors.inject([]) do |possibilities, processor|
          possibilities + processor.possible_errors
        end
      end
    end
  end
end
