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

      # TODO: can we get away with overriding process instead?
      def process_outcome(old_outcome)
        processors.inject(old_outcome) do |outcome, processor|
          processor.process_outcome(outcome)
        end
      end

      def applicable?(value)
        processors.any? { |processor| processor.applicable?(value) }
      end
    end
  end
end
