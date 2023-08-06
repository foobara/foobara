require "active_support/core_ext/object/deep_dup"

Foobara::Util.require_directory("#{__dir__}/model")

module Foobara
  class Model
    [
      Schemas::Duck,
      Schemas::Symbol,
      Schemas::Integer,
      Schemas::Attributes
    ].each do |schema_class|
      schema_class.autoregister_processors
      Schema::Registry.global.register(schema_class)
    end
  end
end
