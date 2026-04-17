module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class IgnoreUnexpectedAttributes < Value::Transformer
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def transform(attributes_hash)
            element_type_declarations = parent_declaration_data[:element_type_declarations]
            expected_attributes = element_type_declarations.keys
            unexpected_attributes = attributes_hash.keys - expected_attributes

            return attributes_hash if unexpected_attributes.empty?

            attributes_hash.slice(*expected_attributes)
          end
        end
      end
    end
  end
end
