module Foobara
  class Model
    class Type
      class Integer < Type
        class << self
          def ruby_class
            ::Integer
          end
        end
      end
    end
  end
end
