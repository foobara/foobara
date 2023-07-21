require "foobara/model/schema"

module Foobara
  class Model
    class DuckSchema < Schema
      include Schema::Concerns::PrimitiveSchema
    end
  end
end
