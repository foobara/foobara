module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.is_a?(::Hash)

            type_symbol = sugary_type_declaration[:type]

            if type_symbol
              if type_symbol.is_a?(::Symbol) && type_registered?(type_symbol)
                type = Foobara.foobara_root_namespace.foobara_lookup_type(
                  type_symbol, mode: Namespace::LookupMode::ABSOLUTE
                )

                type&.extends?(BuiltinTypes[expected_type_symbol])
              end
            end
          end

          def expected_type_symbol
            :model
          end

          def desugarize(sugary_type_declaration)
            Util.symbolize_keys(sugary_type_declaration)
          end

          def priority
            Priority::HIGH
          end
        end
      end
    end
  end
end
