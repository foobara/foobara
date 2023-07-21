module Foobara
  class Model
    class << self
      def global_registry
        @global_registry ||= Registry.new
      end

      delegate :register_type, :types, to: :global_registry
    end

    register_type(Type::Integer.new)
    register_type(Type::Attributes.new)
    register_type(Type::Duck.new)

    Schema.register_schema(IntegerSchema)
    Schema.register_schema(DuckSchema)
    Schema.register_schema(AttributesSchema)
  end
end
