Foobara.require_file(
  "type_declarations",
  "handlers/extend_registered_type_declaration/to_type_transformer"
)

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            super.tap do |type|
              key_type_declaration = type.declaration_data[:key_type_declaration]
              value_type_declaration = type.declaration_data[:value_type_declaration]

              if key_type_declaration || value_type_declaration
                type.element_types = [
                  type_for_declaration(key_type_declaration || :duck),
                  type_for_declaration(value_type_declaration || :duck)
                ]
              end
            end
          end
        end
      end
    end
  end
end
