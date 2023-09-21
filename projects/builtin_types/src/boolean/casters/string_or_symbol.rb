module Foobara
  module BuiltinTypes
    module Boolean
      module Casters
        class StringOrSymbol < Value::Caster
          TRUE_VALUES =  Set["true", "t", "1", "yes", "y"]
          FALSE_VALUES = Set["false", "f", "0", "no", "n"]
          ALLOWED_VALUES = TRUE_VALUES | FALSE_VALUES

          def applicable?(value)
            value = value.to_s if value.is_a?(::Symbol)

            value.is_a?(::String) && ALLOWED_VALUES.include?(value.downcase)
          end

          def applies_message
            "be a String or Symbol that is one of #{ALLOWED_VALUES.join(", ")} (case-insensitive)"
          end

          def cast(value)
            TRUE_VALUES.include?(value.to_s.downcase)
          end
        end
      end
    end
  end
end
