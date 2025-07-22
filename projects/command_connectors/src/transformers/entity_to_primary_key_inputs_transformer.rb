module Foobara
  module CommandConnectors
    module Transformers
      class EntityToPrimaryKeyInputsTransformer < TypeDeclarations::TypedTransformer
        def from_type_declaration
          return nil unless to_type

          if contains_associations_or_is_entity?(to_type)
            if to_type.extends?(Foobara::BuiltinTypes[:attributes])
              to_fix = {}

              to_type.element_types.each_pair do |attribute_name, attribute_type|
                if contains_associations_or_is_entity?(attribute_type)
                  to_fix[attribute_name] = attribute_type
                end
              end

              element_type_declarations = to_type.declaration_data[:element_type_declarations].dup

              to_fix.each_pair do |attribute_name, attribute_type|
                transformer = EntityToPrimaryKeyInputsTransformer.new(to: attribute_type)
                element_type_declarations[attribute_name] = transformer.from_type_declaration
              end

              to_type.declaration_data.merge(element_type_declarations:)
            elsif to_type.extends?(Foobara::BuiltinTypes[:tuple])
              indexes_to_fix = []

              to_type.element_types.each.with_index do |element_type, index|
                if contains_associations_or_is_entity?(element_type)
                  indexes_to_fix << index
                end
              end

              element_type_declarations = to_type.declaration_data[:element_type_declarations].dup

              indexes_to_fix.each do |index|
                transformer = EntityToPrimaryKeyInputsTransformer.new(to: to_type.element_types[index])
                element_type_declarations[index] = transformer.from_type_declaration
              end

              to_type.declaration_data.merge(element_type_declarations:)
            elsif to_type.extends?(Foobara::BuiltinTypes[:array])
              transformer = EntityToPrimaryKeyInputsTransformer.new(to: to_type.element_type)
              element_type_declaration = transformer.from_type_declaration

              to_type.declaration_data.merge(element_type_declaration:)
            elsif to_type.extends?(Foobara::BuiltinTypes[:detached_entity])
              declaration = to_type.target_class.primary_key_type.reference_or_declaration_data

              description = "#{to_type.target_class.model_name} #{to_type.target_class.primary_key_attribute}"

              unless to_type.extends_directly?(Foobara::BuiltinTypes[:detached_entity]) ||
                     to_type.extends_directly?(Foobara::BuiltinTypes[:entity])

                description = [
                  description,
                  *to_type.description
                ].join(" : ")
              end

              declaration[:description] = description

              if to_type.declaration_data.key?(:allow_nil)
                declaration[:allow_nil] = to_type.declaration_data[:allow_nil]
              end

              declaration
            elsif to_type.extends?(Foobara::BuiltinTypes[:model])
              attributes_type = to_type.target_class.attributes_type
              EntityToPrimaryKeyInputsTransformer.new(to: attributes_type).from_type_declaration
            else
              # :nocov:
              raise "Not sure how to handle #{to_type}"
              # :nocov:
            end
          else
            to_type
          end
        end

        def transform(inputs)
          inputs
        end

        private

        def contains_associations_or_is_entity?(type)
          DetachedEntity.contains_associations?(type) || type.extends?(Foobara::BuiltinTypes[:detached_entity])
        end
      end
    end
  end
end
