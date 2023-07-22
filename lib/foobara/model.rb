Foobara::Util.require_directory("#{__dir__}/model")

module Foobara
  class Model
    Schema.register_schema(IntegerSchema)
    Schema.register_schema(DuckSchema)
    Schema.register_schema(AttributesSchema)
  end
end
