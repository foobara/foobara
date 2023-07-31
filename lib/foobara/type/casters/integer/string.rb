require "foobara/type/caster"

# TODO: move this to casters directory
module Foobara
  class Type
    module ValueProcessors
      module Integer
        class CastFromString < Caster
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
