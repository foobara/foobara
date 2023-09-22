module Foobara
  module BuiltinTypes
    module Datetime
      module Casters
        # TODO: there seems to be an issue with the design here. We cast first and casters are
        # transformers (don't return errors.)  However, it would probably give a better error if we could
        # indicate exactly what was wrong with this hash instead of a catch-all error mixed with all the other
        # casters errors. The obvious solution is to inherit Value::Processor instead. Maybe that would just work
        # without any other changes needed.
        # TODO: try that
        class Hash < TypeDeclarations::Caster
          def applicable?(hash)
            hash.is_a?(::Hash) && valid_hash?(hash)
          end

          def applies_message
            "be a Hash with :year, :month, :day, :hours, :minutes, :seconds, :milliseconds, and :zone keys"
          end

          def cast(hash)
            hash = datetime_attributes_type.process_value!(hash)

            year = hash[:year]
            month = hash[:month]
            day = hash[:day]
            hours = hash[:hours]
            minutes = hash[:minutes]
            seconds = hash[:seconds]
            milliseconds = hash[:milliseconds]
            zone = hash[:zone]

            if milliseconds
              seconds = seconds.to_r + (milliseconds.to_r / 1000)
            end

            ::Time.new(year, month, day, hours, minutes, seconds, zone)
          end

          def datetime_attributes_type
            @datetime_attributes_type ||= type_for_declaration(
              year: :integer,
              month: { type: :integer, min: 1, max: 12 },
              day: { type: :integer, min: 1, max: 31 },
              hours: { type: :integer, min: 0, max: 23, required: false, default: 0 },
              minutes: { type: :integer, min: 0, max: 59, required: false, default: 0 },
              seconds: { type: :big_decimal, min: 0, max: 59, required: false, default: 0 },
              milliseconds: { type: :integer, min: 0, max: 1000, required: false },
              zone: { type: :string, required: false }
            )
          end

          private

          def valid_hash?(hash)
            # TODO: use a #runner to memoize this?
            outcome = datetime_attributes_type.process_value(hash)

            if outcome.success?
              hash = outcome.result

              year = hash[:year]
              month = hash[:month]
              day = hash[:day]
              zone = hash[:zone]

              ::Date.valid_date?(year, month, day) && (zone.nil? || valid_zone?(zone))
            end
          end

          def valid_zone?(zone)
            !!Time.zone_offset(zone)
          end
        end
      end
    end
  end
end
