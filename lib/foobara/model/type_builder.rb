module Foobara
  class Model
    class TypeBuilder
      class << self
        def type_cache
          @type_cache ||= {}
        end

        def builder_registry
          @builder_registry ||= {}
        end

        def type_for(schema)
          schema_hash = schema.to_h
          type = type_cache[schema_hash]

          return type if type

          type_cache[schema_hash] = builder_for(schema).to_type
        end

        def builder_for(schema)
          builder_class = builder_registry[schema.type] || TypeBuilder

          builder_class.new(schema)
        end
      end

      attr_accessor :schema

      def initialize(schema)
        self.schema = schema
      end

      def to_type
        Foobara::Type[symbol] || Foobara::Type.new(**to_args)
      end

      def to_args
        {
          casters:
        }
      end

      def symbol
        @symbol ||= schema.type
      end

      def casters
        raise "subclass responsibility"
      end

      builder_registry[:attributes] = TypeBuilder::Attributes
      builder_registry[:integer] = TypeBuilder::Integer
    end
  end
end
