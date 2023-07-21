module Foobara
  class Model
    class TypeBuilder
      def to_type
        Type.new(
          caster:,
          symbol:,
          ruby_class:
        )
      end

      def ruby_class
        @ruby_class ||= Object.const_get(symbol.to_s.classify)
      end

      def caster
        @caster ||= begin
          # TODO: this is crazy to do this here. Make this not necessary.
          Util.require_pattern("#{__dir__}/type/*/casters/*.rb")

          direct_caster = Foobara::Model::Type::Casters::DirectTypeMatchCaster.new(
            type_symbol: symbol,
            ruby_class:
          )

          casters = if casters_module
                      Util.constant_values(casters_module, Class)
                    end

          if casters.blank?
            direct_caster
          else
            casters = casters.map do |caster_class|
              caster_class.new(type_symbol: symbol, ruby_class:)
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
