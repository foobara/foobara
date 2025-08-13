module Foobara
  module BuiltinTypes
    module Float
      module Casters
        class Integer < Value::Caster
          def applicable?(value)
            binding.pry if value.is_a?(TypeDeclaration)
            value.is_a?(::Integer)
          end

          def applies_message
            "be a an Integer"
          end

          def cast(integer)
            integer.to_f
          end
        end
      end
    end
  end
end
