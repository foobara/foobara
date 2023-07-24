require "foobara/type/value_processor"

module Foobara
  class Type
    module ValueProcessors
      module Integer
        class CastFromString < ValueProcessor
          INTEGER_REGEX = /^-?\d+$/

          def applicable?(value)
            value.is_a?(::String)
          end

          def error_halts_processing?
            true
          end

          def process(string)
            if string =~ INTEGER_REGEX
              Outcome.success(string.to_i)
            else
              Outcome.errors(
                CannotCastError.new(
                  message: "#{string} is not a string matching #{INTEGER_REGEX}",
                  context: {
                    cast_to_type: :integer,
                    value: string
                  }
                )
              )
            end
          end
        end
      end
    end
  end
end
