module Foobara
  class Model
    class IntegerSchema < Schema
      include Schema::Concerns::PrimitiveSchema
    end
  end
end
