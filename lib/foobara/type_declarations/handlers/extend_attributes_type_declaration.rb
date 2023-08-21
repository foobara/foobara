module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = desugarize(sugary_type_declaration)

          strictish_type_declaration[:type] == :attributes
        end
      end
    end
  end
end
