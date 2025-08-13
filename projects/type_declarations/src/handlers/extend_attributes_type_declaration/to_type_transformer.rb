Foobara.require_project_file("type_declarations", "handlers/registered_type_declaration/to_type_transformer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ToTypeTransformer < ExtendAssociativeArrayTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            type = super
            type.element_types = :Attributes
            type
          end
        end
      end
    end
  end
end
