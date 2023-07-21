module Foobara
  class Model
    class Type
      class Attributes < Type
        class << self
          def ruby_class
            ::Hash
          end
        end
      end
    end
  end
end
