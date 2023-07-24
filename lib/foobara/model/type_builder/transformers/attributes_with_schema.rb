module Foobara
  class Model
    class Type
      module Casters
        class AttributesWithSchema < Foobara::Type::Caster
          attr_accessor :schema

          def initialize(schema)
            # this feels odd to pass this symbol around... it doesn't mean the same thing for a type as it does
            # for a schema type.
            super(type_symbol: schema.type)
            self.schema = schema
          end

          def applicable?(value)
            value.is_a?(Hash)
          end

          def cast_from(hash)
            outcome = symbolize_keys(hash)

            return outcome unless outcome.success?

            hash = outcome.result

            validate_keys(hash)

            # TODO: work on this...
          end

          def validate_keys(hash)
            hash.each_key do |key|
              unless allowed_attribute_keys.include?(key)
                return Outcome.error(
                  CannotCastError.new(
                    message: "#{key} is not a valid attribute name. Expected one of #{allowed_attribute_keys}",
                    context: {
                      cast_to_type: type_symbol,
                      value: hash
                    }
                  )
                )
              end
            end
          end

          def allowed_attribute_keys
            @allowed_attribute_keys ||= schema.schemas.keys
          end

          def symbolize_keys(hash)
            keys = hash.keys
            non_symbolic_keys = keys.reject { |key| key.is_a?(Symbol) }

            if non_symbolic_keys.empty?
              Outcome.success(hash)
            elsif non_symbolic_keys.all? { |key| key.is_a?(String) }
              Outcome.success(hash.symbolize_keys)
            else
              Outcome.errors(
                CannotCastError.new(
                  message: "#{hash} contains keys that are not symbolizable: #{non_symbolic_keys}",
                  context: {
                    cast_to_type: type_symbol,
                    value: hash
                  }
                )
              )
            end
          end
        end
      end
    end
  end
end
