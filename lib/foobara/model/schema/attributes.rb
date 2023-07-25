module Foobara
  class Model
    class Schema
      class Attributes < Schema
        class << self
          def can_handle?(sugary_schema)
            return false unless sugary_schema.is_a?(Hash)

            sugary_schema.keys.all? { |key| key.is_a?(::Symbol) }
          end
        end

        def schemas
          strict_schema[:schemas]
        end

        def defaults
          strict_schema[:defaults] || {}
        end

        def required
          strict_schema[:required] || []
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
            non_symbolic = schemas.keys.reject { |key| key.is_a?(::Symbol) }

            if non_symbolic.present?
              Error.new(
                symbol: :non_symbolic_attribute_keys_given,
                message: "Attributes must have all symbolic keys but #{non_symbolic} were given instead",
                context: {
                  non_symbolic:
                }
              )
            else
              default_validation_errors
            end
          end || []
        end

        def default_validation_errors
          if defaults.present?
            if defaults.is_a?(Hash) && defaults.keys.all? { |key| key.is_a?(::Symbol) }
              defaults.keys.map do |key|
                unless valid_attribute_names.include?(key)
                  Error.new(
                    symbol: :invalid_default_value_given,
                    message: "#{key} is not a valid default key, expected one of #{valid_attribute_names}",
                    context: {
                      invalid_key: key,
                      valid_attribute_names:,
                      defaults:
                    }
                  )
                end
              end.compact.presence
            else
              Error.new(
                symbol: :invalid_default_values_given,
                message: "defaults should be a hash with symbolic keys",
                context: {
                  defaults:
                }
              )
            end
          end
        end

        def to_h
          super.merge(
            schemas: schemas.transform_values(&:to_h),
            required:,
            defaults:
          )
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

          hash = if strictish_schema?
                   raw_schema.deep_dup
                 else
                   {
                     type: :attributes,
                     schemas: raw_schema.deep_dup
                   }
                 end

          unless hash[:schemas].keys.all? { |attribute_name| attribute_name.is_a?(::Symbol) }
            errors << Error.new(
              symbol: :expected_a_hash,
              message: "Attributes must be a hash",
              context: {
                raw_schema:
              }
            )
            return
          end

          hash = desugarize_defaults(hash)
          hash = desugarize_required(hash)

          hash[:schemas] = hash[:schemas].transform_values do |attribute_schema|
            Schema.for(attribute_schema)
          end

          hash
        end

        def strictish_schema?
          raw_schema.key?(:type) && raw_schema.key?(:schemas) &&
            raw_schema.keys - %i[type schemas defaults required] == []
        end

        def desugarize_defaults(hash)
          hash[:defaults] ||= {}

          schemas = hash[:schemas]
          schemas.each_pair do |attribute_name, attribute_schema|
            if attribute_schema.is_a?(Hash) && attribute_schema.key?(:default)
              default = attribute_schema[:default]
              schemas[attribute_name] = attribute_schema.except(:default)
              hash[:defaults] = hash[:defaults].merge(attribute_name => default)
            end
          end

          hash
        end

        def desugarize_required(hash)
          hash[:required] = Array.wrap(hash[:required])

          schemas = hash[:schemas]
          schemas.each_pair do |attribute_name, attribute_schema|
            if attribute_schema.is_a?(Hash) && attribute_schema.key?(:required)
              required = attribute_schema[:required]
              if required # required: false is a no-op as it's the default
                schemas[attribute_name] = attribute_schema.except(:required)
                hash[:required] += [attribute_name]
              end
            end
          end

          hash
        end
      end
    end
  end
end
