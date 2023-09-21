Foobara::Util.require_project_file("type_declarations/handlers/registered_type_declaration/to_type_transformer")
Foobara::Util.require_project_file("type_declarations/handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ToTypeTransformer < ExtendAssociativeArrayTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            super.tap do |type|
              type_declarations = type.declaration_data[:element_type_declarations]
              type.element_types = type_declarations.transform_values do |attribute_declaration|
                type_for_declaration(attribute_declaration)
              end
            end
          end
        end
      end
    end
  end
end
