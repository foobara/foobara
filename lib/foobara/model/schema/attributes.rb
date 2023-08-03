module Foobara
  class Model
    class Schema
      class Attributes < Schema
        class << self
          def can_handle?(hash)
            hash.is_a?(::Hash) && all_keys_symbolizable?(hash) &&
              (!strictish_schema?(hash) || all_keys_symbolizable?(hash.symbolize_keys[:schemas]))
          end

          private

          def all_keys_symbolizable?(hash)
            hash.keys.all? do |key|
              key.is_a?(::Symbol) || key.is_a?(::String)
            end
          end

          def strictish_schema?(hash)
            keys = hash.keys.map(&:to_sym)
            keys.include?(:type) && keys.include?(:schemas)
          end
        end

        def schemas
          strict_schema[:schemas]
        end

        # TODO: having defaults and required hard-coded here is probably fine but does make it less likely
        # to have a system where extensions can easily be added at the attributes level.
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

        def build_schema_validation_errors
          super(skip: %i[schemas required defaults])

          if schemas.blank?
            # TODO: should probably be some kind of schema validation error instead of Error
            schema_validation_errors << Error.new(
              symbol: :missing_schemas_key_for_attributes,
              message: "Attributes must always have schemas present",
              context: {
                schema: to_h
              }
            )
          else
            non_symbolic = schemas.keys.reject { |key| key.is_a?(::Symbol) }

            if non_symbolic.present?
              schema_validation_errors << Error.new(
                symbol: :non_symbolic_attribute_keys_given,
                message: "Attributes must have all symbolic keys but #{non_symbolic} were given instead",
                context: {
                  non_symbolic:
                }
              )
            else
              # TODO: having defaults and required hard-coded here is probably fine but does make it less likely
              # to have a system where extensions can easily be added at the attributes level.
              self.schema_validation_errors +=
                Array.wrap(default_validation_errors) + Array.wrap(required_attribute_validation_errors)
            end
          end
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

        def required_attribute_validation_errors
          if required.present?
            if required.is_a?(Array) && required.all? { |key| key.is_a?(::Symbol) }
              required.map do |key|
                unless valid_attribute_names.include?(key)
                  Error.new(
                    symbol: :invalid_required_attribute_name_given,
                    message: "#{key} is not a valid default key, expected one of #{valid_attribute_names}",
                    context: {
                      invalid_required_attribute_name: key,
                      valid_attribute_names:,
                      required:
                    }
                  )
                end
              end.compact.presence
            else
              Error.new(
                symbol: :invalid_required_attributes_values_given,
                message: "required should be an array of symbols",
                context: {
                  required:
                }
              )
            end
          end
        end

        def to_h
          super.merge(
            schemas: schemas.transform_values(&:to_h)
          )
        end

        private

        def desugarizers
          deep_dup = ->(hash) { hash.deep_dup }
          symbolize_keys = ->(hash) { hash.symbolize_keys }
          to_strictish_schema = ->(hash) {
            if hash.key?(:type) && hash.key?(:schemas)
              hash
            else
              {
                type: :attributes,
                schemas: hash.deep_dup
              }
            end
          }
          symbolize_schemas = ->(hash) {
            hash[:schemas] = hash[:schemas].symbolize_keys
            hash
          }
          schemaize_schemas = ->(hash) {
            hash[:schemas] = hash[:schemas].transform_values do |attribute_schema|
              Schema.for(attribute_schema, schema_registries:)
            end

            hash
          }

          [
            deep_dup,
            symbolize_keys,
            to_strictish_schema,
            symbolize_schemas,
            *super,
            schemaize_schemas
          ]
        end

        def strictish_schema?
          raw_schema.key?(:type) && raw_schema.key?(:schemas) &&
            raw_schema.keys - %i[type schemas defaults required] == []
        end
      end
    end
  end
end
