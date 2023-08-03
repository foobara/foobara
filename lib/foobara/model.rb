require "active_support/core_ext/object/deep_dup"

Foobara::Util.require_directory("#{__dir__}/model")

module Foobara
  class Model
    Schema.register_schema(Schema::Duck)
    Schema.register_schema(Schema::Symbol)
    Schema.register_schema(Schema::Integer)
    Schema.register_schema(Schema::Attributes)
  end
end
