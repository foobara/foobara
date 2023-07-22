module Foobara
  class Model
    class TypeBuilder
      def to_type
        Type.new(
          caster:,
          symbol:
        )
      end

      def ruby_class
        @ruby_class ||= Object.const_get(symbol.to_s.classify)
      end

      def caster
        @caster ||= begin
          direct_caster = Foobara::Model::Type::Casters::DirectTypeMatchCaster.new(
            type_symbol: symbol,
            ruby_class: # how to handle type :boolean with TrueClass and FalseClass? We need two of these for that.
          )

          casters = if casters_module
                      Util.constant_values(casters_module, Class)
                    end

          if casters.blank?
            direct_caster
          else
            casters = casters.map do |caster_class|
              caster_class.new(type_symbol: symbol)
            end

            Type::CasterCollection.new(direct_caster, *casters)
          end
        end
      end

      def casters_module
        @casters_module ||= begin
          type_module = Util.constant_value(Foobara::Model::Type, symbol.to_s.classify)

          if type_module
            Util.constant_value(type_module, :Casters)
          end
        end
      end
    end
  end
end
