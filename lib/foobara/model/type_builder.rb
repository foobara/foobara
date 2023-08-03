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
        Foobara::Type.new(**to_args)
      end

      def to_args
        {
          casters:,
          value_transformers:,
          value_validators:
        }
      end

      def symbol
        @symbol ||= schema.type
      end

      def casters
        type_module_name = symbol.to_s.camelize.to_sym

        casters_module = Util.constant_value(Type::Casters, type_module_name)
        casters = Util.constant_values(casters_module, Class)

        direct_caster = casters.find { |caster| caster.name.to_sym == type_module_name }

        direct_caster = Array.wrap(direct_caster)

        casters -= direct_caster

        [*direct_caster, *casters].compact.map(&:instance)
      end

      def value_transformers
        transformers = base_type&.value_transformers.dup || []

        schema.transformers_for_type(symbol).each_pair do |transformer_symbol, transformer_class|
          if schema.strict_schema.key?(transformer_symbol)
            transformers << transformer_class.new(schema.strict_schema[transformer_symbol])
          end
        end

        transformers
      end

      def value_validators
        validators = base_type&.value_validators.dup || []

        schema.validators_for_type(symbol).each_pair do |validator_symbol, validator_class|
          if schema.strict_schema.key?(validator_symbol)
            validators << validator_class.new(schema.strict_schema[validator_symbol])
          end
        end

        validators
      end

      builder_registry[:attributes] = TypeBuilder::Attributes
    end
  end
end
