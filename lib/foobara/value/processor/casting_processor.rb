require "foobara/value/selection_processor"

module Foobara
  module Value
    class CastingProcessor < SelectionProcessor
      class << self
        def error_classes
          # TODO: relocate this class here
          [CannotCastError]
        end
      end

      # TODO: get this thing out of here and onto Model
      def initialize(*args, casters:)
        super(*args, processors: casters)
      end

      def casters
        processors
      end

      def error_message(value)
        words_connector = ", "
        last_word_connector = two_words_connector = ", or "

        applies_message = casters.map(&:applies_message).flatten.to_sentence(
          words_connector:,
          last_word_connector:,
          two_words_connector:
        )

        "Cannot cast #{value}. Expected it to #{applies_message}"
      end

      def error_context(value)
        {
          cast_to: casters.first.type_symbol,
          value:
        }
      end

      def process(value)
        outcome = super

        outcome.success? ? outcome : HaltedOutcome.error(build_error(value))
      end

      def possible_errors
        possibilities = super

        # TODO: replace NoApplicableProcessorError with CannotCastError
      end
    end
  end
end
