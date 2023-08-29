require "foobara/value/data_error"

module Foobara
  module Value
    class Processor
      # TODO: at least move this up to Types though that doesn't solve the issue
      class Casting < Selection
        class CannotCastError < DataError; end

        class << self
          def error_classes
            [CannotCastError]
          end
        end

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
            cast_to:,
            value:
          }
        end

        def build_error(
          *args,
          **opts
        )
          super(
            *args,
            **opts.merge(error_class:)
          )
        end

        def cast_to
          # TODO: isn't there a way to declare declaration_data_type so we don't have to validate here??
          unless declaration_data.key?(:cast_to)
            # :nocov:
            raise "Missing cast_to"
            # :nocov:
          end

          declaration_data[:cast_to]
        end

        def process(value)
          outcome = super

          outcome.success? ? outcome : HaltedOutcome.error(build_error(value))
        end
      end
    end
  end
end
