module Foobara
  class Model
    module Types
      class DuckType < Type
        class << self
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
end
