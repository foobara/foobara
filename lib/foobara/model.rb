module Foobara
  class Model
    class << self
      def global_registry
        @global_registry ||= Registry.new
      end

      delegate :register_type, :types, to: :global_registry
    end

    register_type(Types::IntegerType.new)
    register_type(Types::AttributesType.new)

    Schema.register_schema(IntegerSchema)
    Schema.register_schema(DuckSchema)
    Schema.register_schema(AttributesSchema)
  end
end
