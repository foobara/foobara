module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          if strict_type_declaration.is_a?(::Hash)
            type_symbol = strict_type_declaration[:type]

            return false if type_symbol == expected_type_symbol

            if type_registered?(type_symbol)
              type = type_for_declaration(type_symbol)
              type.extends_symbol?(expected_type_symbol)
            end
          end
        end

        def expected_type_symbol
          :model
        end

        def priority
          super - 1
        end
      end
    end
  end
end
