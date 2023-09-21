module Foobara
  module BuiltinTypes
    module Datetime
      module Casters
        class String < Value::Caster
          def applicable?(value)
            value.is_a?(::String) && parse(value)
          end

          def applies_message
            "be a valid date string"
          end

          def cast(string)
            parse(string)
          end

          private

          def parse(string)
            # would be nice to do this some other way where we can verify against a regex independent of casting
            # to a Time especially since ArgumentError is way too generic. But might have to just stick with this
            ::Time.parse(string)
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end
