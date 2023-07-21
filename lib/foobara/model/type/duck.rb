module Foobara
  class Model
    class Type
      class Duck < Type
        def cast_from(object)
          object
        end

        def can_cast?(_object)
          true
        end
      end
    end
  end
end
