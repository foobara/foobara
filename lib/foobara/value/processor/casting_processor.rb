module Foobara
  module Value
    module Processor
      class Casting < Selection
        class CannotCastError < AttributeError
          class << self
            def context_type
              # TODO: hmmmm this is a backwards dependency here, dang...
              # TODO: fix this...
              @context_type ||= Model::Schemas::Attributes.new(context_schema).to_type
            end

            # Value will always need to be a duck but cast_to: should probably be the relevant
            # type-declaration.  This means it shouldn't come from the class but rather the processor
            def context_schema
              {
                cast_to: :duck,
                value: :duck,
                attribute_name: :symbol
              }
            end
          end

          def initialize(**opts)
            super(**opts.merge(symbol: :cannot_cast))
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
end
