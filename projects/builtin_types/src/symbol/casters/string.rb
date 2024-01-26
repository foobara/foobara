module Foobara
  module BuiltinTypes
    module Symbol
      module Casters
        class String < Value::Caster
          def applicable?(value)
            value.is_a?(::String)
          end

          def applies_message
            "be a String"
          end

          def cast(string)
            string.to_sym
          end
        end
      end
    end
  end
end
