module Foobara
  class Model
    class Schema
      class Attributes < Schema
        class << self
          def can_handle?(sugary_schema)
            return false unless sugary_schema.is_a?(Hash)

            sugary_schema.keys.all? { |key| key.is_a?(Symbol) }
          end
        end

        def schemas
          strict_schema[:schemas]
        end

        def valid_attribute_name?(attribute_name)
          valid_attribute_names.include?(attribute_name)
        end

        def valid_attribute_names
          schemas.keys
        end

        def schema_validation_errors
          if schemas.blank?
            Error.new(
              symbol: :missing_schemas_key_for_attributes,
              message: "Attributes must always have schemas present",
              context: {
                schema: to_h
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
          end || []
        end

        def to_h
          {
            type:,
            schemas: schemas.transform_values(&:to_h)
          }
        end

        private

        def desugarize
          unless raw_schema.is_a?(Hash)
            errors << Error.new(
              symbol: :expected_a_hash,
              message: "Attributes must be a hash",
              context: {
                raw_schema:
              }
            )
            return
          end

          hash = if raw_schema.keys.length == 2 && raw_schema.key?(:type) && raw_schema.key?(:schemas)
                   raw_schema
                 else
                   {
                     type: :attributes,
                     schemas: raw_schema
                   }
                 end

          unless hash[:schemas].keys.all? { |attribute_name| attribute_name.is_a?(Symbol) }
            errors << Error.new(
              symbol: :expected_a_hash,
              message: "Attributes must be a hash",
              context: {
                raw_schema:
              }
            )
            return
          end

          hash[:schemas] = hash[:schemas].transform_values do |attribute_schema|
            Schema.for(attribute_schema)
          end

          hash
        end
      end
    end
  end
end
