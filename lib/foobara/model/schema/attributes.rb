module Foobara
  class Model
    class Schema
      class Attributes < Schema
        class << self
          def can_handle?(hash)
            hash.is_a?(::Hash) && Util.all_symbolizable_keys?(hash) &&
              (!strictish_schema?(hash) || Util.all_symbolizable_keys?(hash.symbolize_keys[:schemas]))
          end

          private

          def strictish_schema?(hash)
            keys = hash.keys.map(&:to_sym)
            keys.include?(:type) && keys.include?(:schemas)
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

        def to_h
          super.merge(
            schemas: schemas.transform_values(&:to_h)
          )
        end

        private

        def allowed_keys
          [:schemas, *super]
        end

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
      end
    end
  end
end
