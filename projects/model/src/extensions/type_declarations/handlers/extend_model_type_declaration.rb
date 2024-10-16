module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          if sugary_type_declaration.is_a?(::Hash)
            desugarize(sugary_type_declaration)[:type] == expected_type_symbol
          end
        end

        def expected_type_symbol
          :model
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
