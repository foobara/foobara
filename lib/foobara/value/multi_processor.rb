require "foobara/value/processor"

module Foobara
  module Value
    class MultiProcessor < Processor
      attr_accessor :processors

      def initialize(*args, processors:)
        self.processors = processors
        super(*args)
      end

      def error_classes
        processors.map(&:error_classes)
      end

      def process_outcome(old_outcome)
        processors.inject(old_outcome) do |outcome, processor|
          processor.process_outcome(outcome)
        end
      end

      def process!(value)
        outcome = process(value)

        if outcome.success?
          outcome.result
        else
          outcome.raise!
        end
      end

      # A transformer with no declaration data or with declaration data of false is considered to be
      # not applicable. Override this wherever different behavior is needed.
      # TODO: do any transformers really need this _value argument to determine applicability??
      def applicable?(value)
        processors.any? { |processor| processor.applicable?(value) }
      end
    end
  end
end
