require "foobara/type_declarations/handlers/registered_type_declaration/to_type_transformer"
require "foobara/type_declarations/handlers/extend_associative_array_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendTupleTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ToTypeTransformer < ExtendAssociativeArrayTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            super.tap do |type|
              element_type_declarations = type.declaration_data[:element_type_declarations]

              if element_type_declarations.present?
                type.element_types = element_type_declarations.map do |element_type_declaration|
                  type_for_declaration(element_type_declaration)
                end
              end
            end
          end
        end
      end
    end
  end
end
