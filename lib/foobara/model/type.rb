module Foobara
  class Model
    class Type
      class << self
        def symbol
          name.demodulize.underscore.to_sym
        end

        def schema_validation_errors_for(strict_schema)
          # hmmmm do we need this??
        end

        def casting_errors(object)
          unless can_cast?(object)
            Error.new(
              symbol: :cannot_cast,
              message: "Could not cast #{object.inspect} to #{symbol}",
              context: {
                cast_to: symbol,
                value: object
              }
            )
          end
        end

        def validation_errors(_object)
          # TODO: override this in relevant base types
          []
        end
      end
    end
  end
end
