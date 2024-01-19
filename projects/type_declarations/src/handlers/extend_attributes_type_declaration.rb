module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = desugarize(sugary_type_declaration)

          strictish_type_declaration.is_a?(::Hash) && strictish_type_declaration[:type] == :attributes
        end

        def starting_desugarizers
          starting_desugarizers_without_inherited
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
