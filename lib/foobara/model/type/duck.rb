module Foobara
  class Model
    class Type
      class Duck < Type
        def ruby_class
          ::Object
        end

        def cast_from(value)
          Outcome.success(value)
        end

        def can_cast?(_object)
          true
        end
      end
    end
  end
end
