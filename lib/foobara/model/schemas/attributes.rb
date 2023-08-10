require "foobara/model/schema"

module Foobara
  class Model
    module Schemas
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

        def to_type
          declaration_data = to_h
          args = to_type_args.merge(children_types:)
          Type::Types::AttributesType.new(declaration_data, **args)
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
          desugarize = ->(hash) {
            hash = hash.deep_dup

            hash.symbolize_keys!

            hash = if hash.key?(:type) && hash.key?(:schemas)
                     hash
                   else
                     {
                       type: :attributes,
                       schemas: hash
                     }
                   end

            hash[:schemas].symbolize_keys!

            hash
          }

          schemaize_schemas = ->(hash) {
            hash[:schemas] = hash[:schemas].transform_values do |attribute_schema|
              schema_registry.schema_for(attribute_schema)
            end

            hash
          }

          [
            desugarize,
            *super,
            schemaize_schemas
          ]
        end

        # Type building override
        def children_types
          @children_types ||= schemas.transform_values(&:to_type)
        end
      end
    end
  end
end
