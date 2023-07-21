module Foobara
  class Model
    class Type
      class Duck < Type
        class << self
          def ruby_class
            ::Object
          end
        end
      end
    end
  end
end
