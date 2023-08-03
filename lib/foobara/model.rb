require "active_support/core_ext/object/deep_dup"

Foobara::Util.require_directory("#{__dir__}/model")

module Foobara
  class Model
    Schema.register_schema(Schemas::Duck)
    Schema.register_schema(Schemas::Symbol)
    Schema.register_schema(Schemas::Integer)
    Schema.register_schema(Schemas::Attributes)
  end
end
