require "active_support/core_ext/object/deep_dup"

Foobara::Util.require_directory("#{__dir__}/model")

module Foobara
  class Model
    Schema::Registry.global.register(Schemas::Duck)
    Schema::Registry.global.register(Schemas::Symbol)
    Schema::Registry.global.register(Schemas::Integer)
    Schema::Registry.global.register(Schemas::Attributes)
  end
end
