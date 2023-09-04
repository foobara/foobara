module Foobara
  module BuiltinTypes
    module BigDecimal
      module Casters
        class Integer < Value::Caster
          def applicable?(value)
            value.is_a?(::Integer)
          end

          def applies_message
            "be a an Integer"
          end

          def cast(integer)
            BigDecimal(integer)
          end
        end
      end
    end
  end
end
