module Foobara
  class Type
    module Casters
      module Integer
        class String < Caster
          INTEGER_REGEX = /^-?\d+$/

          def applicable?(value)
            value.is_a?(::String)
          end

          def cast_from(string)
            if string =~ INTEGER_REGEX
              Outcome.success(string.to_i)
            else
              Outcome.errors(
                CannotCastError.new(
                  message: "#{string} is not a string matching #{INTEGER_REGEX}",
                  context: {
                    cast_to_type: type_symbol,
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
