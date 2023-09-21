Foobara.require_file("type_declarations", "handlers/registered_type_declaration/to_type_transformer")
Foobara.require_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ToTypeTransformer < ExtendAssociativeArrayTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            super.tap do |type|
              element_type_declaration = type.declaration_data[:element_type_declaration]

              if element_type_declaration
                type.element_type = type_for_declaration(element_type_declaration)
              end
            end
          end
        end
      end
    end
  end
end
