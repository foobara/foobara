require "foobara/value/processor"

module Foobara
  module Value
    class CastingProcessor < Processor
      attr_accessor :casters

      # TODO: get this thing out of here and onto Model
      def initialize(*args, casters:)
        self.casters = casters
        super(*args)
      end

      def error_class
        CannotCastError
      end

      # TODO: shouldn't need to override both of these methods
      def error_classes
        [error_class]
      end

      def caster_for(value)
        casters.find { |c| c.applicable?(value) }
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

      def error_context_type
        error_class.context_type
      end

      def process(value)
        caster = caster_for(value)

        if caster
          caster.process(value)
        else
          Value::HaltedOutcome.error(build_error(value))
        end
      end

      def always_applicable?
        true
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
