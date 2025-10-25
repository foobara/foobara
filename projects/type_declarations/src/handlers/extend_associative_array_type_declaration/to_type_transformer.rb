require_relative "../extend_registered_type_declaration/to_type_transformer"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            type = super
            type.element_types_loader = LazyElementTypes::Hash
            type
          end
        end
      end
    end
  end
end
