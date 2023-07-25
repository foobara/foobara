module Foobara
  class Model
    class Schema
      class Symbol < Schema
        include Schema::Concerns::Primitive
      end
    end
  end
end
