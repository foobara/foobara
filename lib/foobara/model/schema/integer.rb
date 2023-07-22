module Foobara
  class Model
    class Schema
      class Integer < Schema
        include Schema::Concerns::Primitive
      end
    end
  end
end
