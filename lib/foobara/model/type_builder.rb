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

        # TODO: schema has a path so why both arguments?
        def type_for(schema)
          schema_hash = schema.to_h

          type = type_cache[schema_hash]

          return type if type

          type_cache[schema_hash] = builder_for(schema).to_type
        end

        def builder_for(schema)
          # TODO: this won't work when we add more types...
          builder_class = builder_registry[schema.type] || TypeBuilder

          builder_class.new(schema)
        end
      end

      attr_accessor :schema

      def initialize(schema)
        self.schema = schema
      end

      delegate :path, to: :schema

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

      # builder_registry[:duck] = TypeBuilder::Duck
      # builder_registry[:symbol] = TypeBuilder::Symbol
      # builder_registry[:integer] = TypeBuilder::Integer
      builder_registry[:attributes] = TypeBuilder::Attributes
    end
  end
end
