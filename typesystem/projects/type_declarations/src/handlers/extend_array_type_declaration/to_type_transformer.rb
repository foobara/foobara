require_relative "../registered_type_declaration/to_type_transformer"
require_relative "../extend_associative_array_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class ToTypeTransformer < ExtendAssociativeArrayTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            type = super
            type.element_type_loader = LazyElementTypes::Array
            type
          end
        end
      end
    end
  end
end
