require "foobara/value/caster"

module Foobara
  module Types
    module Casters
      module Symbol
        class String < Value::Caster
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