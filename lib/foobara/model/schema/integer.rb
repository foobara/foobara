module Foobara
  class Model
    class Schema
      class Integer < Schema
        include Schema::Concerns::Primitive

        # how can we build this in a cleaner way so that validators can be more easily registered on types
        def to_h
          h = super

          Schema.validators_for_type(:integer).each_key do |validator_symbol|
            value = strict_schema[validator_symbol]
            h = h.merge(validator_symbol => value)
          end

          h
        end

        def schema_validation_errors
          errors = Array.wrap(super)

          validators = Schema.validators_for_type(:integer)
          allowed_keys = [*validators.keys, :type]

          strict_schema.each_pair do |key, value|
            next if key == :type

            if allowed_keys.include?(key)
              validator = validators[key]

              outcome = TypeBuilder.type_for(Schema.for(validator.data_schema)).process(value)

              unless outcome.success?
                errors += outcome.errors
              end
            else
              errors << Error.new(
                symbol: :invalid_schema_element,
                message: "Found #{key} but expected one of #{allowed_keys}"
              )
            end
          end

          errors
        end
      end
    end
  end
end
