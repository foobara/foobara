module Foobara
  module BuiltinTypes
    module BigDecimal
      module Casters
        class String < Value::Caster
          FLOAT_REGEX = /^-?\d+(\.\d+)?([eE]-?\d+)?$/

          def applicable?(value)
            value.is_a?(::String) && value =~ FLOAT_REGEX
          end

          def applies_message
            "be a string of digits with one decimal point optionally amongst " \
              "them and optionally with a minus sign in front and optionally an exponent denoted with e"
          end

          def cast(string)
            BigDecimal(string)
          end
        end
      end
    end
  end
end
