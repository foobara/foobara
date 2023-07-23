module Foobara
  class Type
    class BuiltinTypeBuilder
      attr_accessor :symbol

      def initialize(symbol)
        self.symbol = symbol
      end

      def to_args
        {
          casters:,
          symbol:
        }
      end

      def direct_cast_ruby_classes
        @direct_cast_ruby_classes ||= {
          duck: ::Object,
          attributes: [],
          map: ::Hash,
          boolean: [::TrueClass, ::FalseClass]
        }[symbol] || Object.const_get(symbol.to_s.camelize)
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
    end
  end
end
