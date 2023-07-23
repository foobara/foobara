module Foobara
  class Model
    class TypeBuilder
      class << self
        def for(schema)
          type_symbol = schema.type

          type = Type[type_symbol]

          return type if type

          Type.new(symbol:, **new(schema).to_args)
        end
      end

      attr_accessor :schema, :direct_cast_ruby_classes

      def initialize(schema, direct_cast_ruby_classes: nil)
        self.schema = schema
        self.direct_cast_ruby_classes = direct_cast_ruby_classes || Object.const_get(symbol.to_s.camelize)
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
        @casters_module ||= begin
          type_module = Util.constant_value(Foobara::Type, symbol.to_s.camelize)

          if type_module
            Util.constant_value(type_module, :Casters)
          end
        end
      end
    end
  end
end
