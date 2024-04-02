module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          if strict_type_declaration.is_a?(::Hash) && strict_type_declaration.key?(:type)
            type_symbol = strict_type_declaration[:type]

            return false if type_symbol == expected_type_symbol

            # If there's only one element, then we are probably attempting a registered type lookup, not
            # extending a registered model to create a new type.
            case strict_type_declaration.size
            when 1
              return false
            when 2
              return false if strict_type_declaration.key?(:_desugarized)
            end

            if type_registered?(type_symbol)
              type = type_for_declaration(type_symbol)
              type.extends?(BuiltinTypes[expected_type_symbol])
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
