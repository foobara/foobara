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

      attr_accessor :schema, :direct_cast_ruby_classes

      def initialize(schema, direct_cast_ruby_classes: nil)
        self.schema = schema
        self.direct_cast_ruby_classes ||= direct_cast_ruby_classes || Object.const_get(symbol.to_s.camelize)
      end

      def to_type
        Foobara::Type.new(**to_args)
      end

      def to_args
        {
          casters:,
          symbol:
        }
      end

      def symbol
        @symbol ||= schema.type
      end

      def casters
        @casters ||= begin
          casters = []

          Array.wrap(direct_cast_ruby_classes).each do |ruby_class|
            casters << Foobara::Type::Casters::DirectTypeMatch.new(
              type_symbol: symbol,
              ruby_class:
            )
          end

          if casters_module
            Util.constant_values(casters_module, Class).each do |caster_class|
              casters << caster_class.new(type_symbol: symbol)
            end
          end

          casters
        end
      end

      def casters_module
        @casters_module ||= Util.constant_value(Foobara::Type::Casters, symbol.to_s.camelize)
      end

      builder_registry[:attributes] = TypeBuilder::Attributes
    end
  end
end
