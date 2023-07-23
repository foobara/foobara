module Foobara
  class Model
    class TypeBuilder
      class << self
        def for(schema)
          type_symbol = schema.type

          direct_cast_ruby_classes = case type_symbol
                                     when :attributes
                                       ::Hash
                                     when :boolean
                                       [TrueClass, FalseClass]
                                     end

          new(schema, direct_cast_ruby_classes:).to_type
        end
      end

      attr_accessor :schema, :direct_cast_ruby_classes

      def initialize(schema, direct_cast_ruby_classes: nil)
        self.schema = schema
        self.direct_cast_ruby_classes = direct_cast_ruby_classes || Object.const_get(symbol.to_s.classify)
      end

      def to_type
        Type.new(
          caster:,
          symbol:
        )
      end

      def symbol
        @symbol ||= schema.type
      end

      def caster
        @caster ||= begin
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

          if casters.size == 1
            casters.first
          else
            Type::CasterCollection.new(casters)
          end
        end
      end

      def casters_module
        @casters_module ||= begin
          type_module = Util.constant_value(Foobara::Type, symbol.to_s.classify)

          if type_module
            Util.constant_value(type_module, :Casters)
          end
        end
      end
    end
  end
end
