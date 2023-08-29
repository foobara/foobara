module Foobara
  module BuiltinTypes
    module String
      module Casters
        class Symbol < Value::Caster
          def applicable?(value)
            value.is_a?(::Symbol)
          end

          def applies_message
            "be a Symbol"
          end

          def cast(string)
            string.to_s
          end
        end
      end
    end
  end
end
