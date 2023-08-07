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
