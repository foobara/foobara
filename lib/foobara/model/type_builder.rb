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

        def clear_type_cache
          @type_cache = nil
        end
      end

      attr_accessor :schema

      def initialize(schema)
        self.schema = schema
      end

      def base_type
        nil
      end

      def to_type
        if Foobara::Type.registered?(symbol)
          Foobara::Type[symbol]
        else
          Foobara::Type.new(**to_args)
        end
      end

      def to_args
        {
          casters:,
          value_processors:
        }
      end

      def symbol
        @symbol ||= schema.type
      end

      def casters
        []
      end

      def value_processors
        processors = base_type&.value_processors.dup || []

        # what about transformers??
        schema.validators_for_type(symbol).each_pair do |validator_symbol, validator_class|
          if schema.strict_schema.key?(validator_symbol)
            processors << validator_class.new(schema.strict_schema[validator_symbol])
          end
        end

        processors
      end

      builder_registry[:attributes] = TypeBuilder::Attributes
      builder_registry[:integer] = TypeBuilder::Integer
    end
  end
end
