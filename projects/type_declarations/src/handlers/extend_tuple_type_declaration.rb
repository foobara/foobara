module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendTupleTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = desugarize(sugary_type_declaration)

          strictish_type_declaration.is_a?(::Hash) && strictish_type_declaration[:type] == :tuple
        end
      end
    end
  end
end
