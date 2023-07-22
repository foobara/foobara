module Foobara
  class Model
    class Schema
      class Duck < Schema
        include Schema::Concerns::Primitive
      end
    end
  end
end
