module Foobara
  module BuiltinTypes
    module String
      module Casters
        class Numeric < Value::Caster
          def applicable?(value)
            value.is_a?(::Numeric)
          end

          def applies_message
            "be a Numeric"
          end

          def cast(string)
            string.to_s
          end
        end
      end
    end
  end
end
