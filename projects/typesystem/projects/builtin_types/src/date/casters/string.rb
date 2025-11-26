module Foobara
  module BuiltinTypes
    module Date
      module Casters
        class String < Value::Caster
          def applicable?(value)
            value.is_a?(::String) && parse(value)
          end

          def applies_message
            "be a valid date string with year-month-day order"
          end

          def cast(string)
            parse(string)
          end

          NOT_DELIMITED_REGEX = /\A(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})\z/
          DELIMITED_REGEX = /\A(?<year>\d{4,})(?<delimiter>[\/\\.|_:;-])(?<month>\d{1,2})\k<delimiter>(?<day>\d{1,2})\z/

          private

          def parse(string)
            match = NOT_DELIMITED_REGEX.match(string) || DELIMITED_REGEX.match(string)

            if match
              year = match[:year].to_i
              month = match[:month].to_i
              day = match[:day].to_i

              if ::Date.valid_date?(year, month, day)
                ::Date.new(year, month, day)
              end
            end
          end
        end
      end
    end
  end
end
