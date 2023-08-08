require "foobara/value/caster"

module Foobara
  class Type < Value::Processor
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

          def call(string)
            string.to_i
          end
        end
      end
    end
  end
end
