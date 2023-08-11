require "foobara/value/caster"

module Foobara
  module Types
    module Casters
      module Integer
        class String < Value::Caster
          include Singleton

          INTEGER_REGEX = /^-?\d+$/

          def applicable?(value)
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
