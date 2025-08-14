module Foobara
  module BuiltinTypes
    module Integer
      module Casters
        class String < Value::Caster
          INTEGER_REGEX = /^-?\d+$/

          def applicable?(value)
            binding.pry if value.is_a?(TypeDeclaration)
            value.is_a?(::String) && value =~ INTEGER_REGEX
          end

          def applies_message
            "be a string of digits optionally with a minus sign in front"
          end

          def cast(string)
            string.to_i
          end
        end
      end
    end
  end
end
