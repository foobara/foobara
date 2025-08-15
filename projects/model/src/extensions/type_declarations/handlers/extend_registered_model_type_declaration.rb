module Foobara
  module TypeDeclarations
    module Handlers
      # Why doesn't this inherit from ExtendModelTypeDeclaration
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strict_type_declaration = if sugary_type_declaration.strict?
                                      sugary_type_declaration
                                    else
                                      desugarize(sugary_type_declaration.clone)
                                    end

          if strict_type_declaration.hash? && strict_type_declaration.key?(:type)
            type_symbol = strict_type_declaration[:type]

            return false if type_symbol == expected_type_symbol
            return false unless type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)

            # TODO: cache this on a #base_type= helper
            type = strict_type_declaration.type || lookup_type(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)

            if type
              if type.extends?(BuiltinTypes[expected_type_symbol])
                unless sugary_type_declaration.equal?(strict_type_declaration)
                  sugary_type_declaration.assign(strict_type_declaration)
                end

                true
              end
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
