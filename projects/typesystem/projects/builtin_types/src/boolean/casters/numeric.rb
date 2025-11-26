module Foobara
  module BuiltinTypes
    module Boolean
      module Casters
        class Numeric < Value::Caster
          def applicable?(value)
            [0, 1].include?(value)
          end

          def applies_message
            "be 0 or 1"
          end

          def cast(value)
            !value.zero?
          end
        end
      end
    end
  end
end
