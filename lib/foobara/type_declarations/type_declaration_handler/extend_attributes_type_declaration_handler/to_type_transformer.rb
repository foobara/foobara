require "foobara/type_declarations/type_declaration_handler/registered_type_declaration_handler/to_type_transformer"
require "foobara/type_declarations/type_declaration_handler/extend_associative_array_type_declaration_handler"

module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class ExtendAttributesTypeDeclarationHandler < ExtendAssociativeArrayTypeDeclarationHandler
        class ToTypeTransformer < ExtendAssociativeArrayTypeDeclarationHandler::ToTypeTransformer
          def transform(strict_type_declaration)
            super.tap do |type|
              type.element_types = type.declaration_data[:element_type_declarations].transform_values do |attribute_declaration|
                type_declaration_handler_registry.type_for(attribute_declaration)
              end
            end
          end
        end
      end
    end
  end
end
