module Foobara
  module BuiltinTypes
    module Datetime
      module Casters
        class SecondsSinceEpoch < Value::Caster
          def applicable?(value)
            value.is_a?(::Integer) || value.is_a?(::Float)
          end

          def applies_message
            "be a an integer or float representing seconds since epoch"
          end

          def cast(seconds_since_epoch)
            Time.at(seconds_since_epoch)
          end
        end
      end
    end
  end
end
