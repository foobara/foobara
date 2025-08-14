module Foobara
  module BuiltinTypes
    module Float
      module Casters
        class String < Value::Caster
          FLOAT_REGEX = /^-?\d+(\.\d+)?([eE]-?\d+)?$/

          def applicable?(value)
            binding.pry if value.is_a?(TypeDeclaration)
            value.is_a?(::String) && value =~ FLOAT_REGEX
          end

          def applies_message
            "be a string of digits with one decimal point optionally amongst " \
              "them and optionally with a minus sign in front and optionally an exponent denoted with e"
          end

          def cast(string)
            string.to_f
          end
        end
      end
    end
  end
end
