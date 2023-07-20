module Foobara
  class Model
    module Types
      class IntegerType < Type
        INTEGER_REGEX = /^-?\d+$/

        def cast_from(object)
          case object
          when Integer
            object
          when INTEGER_REGEX
            object.to_i
          else
            raise "There must but a bug in can_cast? for #{symbol} #{object.inspect}"
          end
        end

        def can_cast?(object)
          object.is_a?(Integer) || (object.is_a?(String) && INTEGER_REGEX.match?(object))
        end
      end
    end
  end
end
