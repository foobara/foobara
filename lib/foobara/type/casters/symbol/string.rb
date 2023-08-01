require "foobara/type/caster"

module Foobara
  class Type
    module Casters
      module Symbol
        class String < Caster
          include Singleton

          def applicable?(value)
            value.is_a?(::String)
          end

          def applies_message
            "be a string"
          end

          def cast(string)
            string.to_sym
          end
        end
      end
    end
  end
end
