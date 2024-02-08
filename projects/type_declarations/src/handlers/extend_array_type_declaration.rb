module Foobara
  module TypeDeclarations
    module Handlers
      # Hmmmm... this inheritance feels backwards
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = desugarize(sugary_type_declaration)

          strictish_type_declaration.is_a?(::Hash) && strictish_type_declaration[:type] == :array
        end
      end
    end
  end
end
