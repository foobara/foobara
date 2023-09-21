module Foobara
  module BuiltinTypes
    module Datetime
      module Casters
        class Date < Value::Caster
          def applicable?(value)
            value.is_a?(::Date)
          end

          def applies_message
            "be a Date"
          end

          def cast(date)
            date.to_time
          end
        end
      end
    end
  end
end
