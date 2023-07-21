module Foobara
  class Model
    class Type
      class Integer < Type
        module Casters
          class String < Caster
            INTEGER_REGEX = /^-?\d+$/

            def cast_from(value)
              if value.is_a?(::String) && value =~ INTEGER_REGEX
                Outcome.success(value.to_i)
              else
                Outcome.errors(
                  CannotCastError.new(
                    message: "#{value} is not a string matching #{INTEGER_REGEX}",
                    context: {
                      cast_to_type: symbol,
                      cast_to_ruby_class: ruby_class,
                      value:
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
end
