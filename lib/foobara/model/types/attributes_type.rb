module Foobara
  module Model
    module Types
      class AttributesType < Type
        def cast_from(object)
          case object
          when Hash
            object.with_indifferent_access
          else
            raise "There must but a bug in can_cast? for #{symbol} #{object.inspect}"
          end
        end

        def can_cast?(object)
          object.is_a?(Hash)
        end

        def schema_validation_errors_for(strict_schema)
          schemas = strict_schema[:schemas]

          if schemas.blank?
            Error.new(
              symbol: :missing_schemas_key_for_attributes,
              message: "Attributes must always have schemas present",
              context: {
                schema: strict_schema
              }
            )
          else
            non_symbolic = schemas.keys.reject { |key| key.is_a?(Symbol) }

            if non_symbolic.present?
              Error.new(
                symbol: :non_symbolic_attribute_keys_given,
                message: "Attributes must have all symbolic keys but #{non_symbolic} were given instead",
                context: {
                  non_symbolic:
                }
              )
            end

          end
        end
      end
    end
  end
end