module Foobara
  module TypeDeclarations
    module Handlers
      # Why doesn't this inherit from ExtendModelTypeDeclaration
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          if strict_type_declaration.is_a?(::Hash) && strict_type_declaration.key?(:type)
            type_symbol = strict_type_declaration[:type]

            return false if type_symbol == expected_type_symbol
            return false unless type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)

            if type_registered?(type_symbol)
              type = lookup_type!(type_symbol)
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
