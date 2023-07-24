require "foobara/type/value_validator"

module Foobara
  class Type
    class CastedValueValidator < ValueValidator
      attr_accessor :allowed_classes, :casters, :type_symbol

      def initialize(type_symbol:, allowed_classes:, casters:)
        super()

        self.type_symbol = type_symbol
        self.casters = casters
        self.allowed_classes = Array.wrap(allowed_classes)
      end

      def error_halts_processing?
        true
      end

      def validation_errors(value)
        if allowed_classes.none? { |klass| value.is_a?(klass) }
          applies_messages = casters.map(&:applies_message).flatten
          applies_message = applies_messages.to_sentence(words_connector: ", ", last_word_connector: ", or ")

          CannotCastError.new(
            message: "Cannot cast #{value}. Expected it to #{applies_message}",
            context: {
              cast_to_type: type_symbol,
              value: string
            }
          )
        end
      end
    end
  end
end
