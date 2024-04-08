module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.is_a?(::Hash)
            return false unless Util.all_symbolizable_keys?(sugary_type_declaration)

            sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)

            type_symbol = sugary_type_declaration[:type] || sugary_type_declaration["type"]
            return false unless type_symbol

            type_symbol = type_symbol.to_sym if type_symbol.is_a?(::String)

            return true if type_symbol == expected_type_symbol

            if type_symbol.is_a?(::Symbol) && type_registered?(type_symbol)
              type = Foobara.foobara_root_namespace.foobara_lookup_type(
                type_symbol, mode: Namespace::LookupMode::ABSOLUTE
              )

              type&.extends?(BuiltinTypes[expected_type_symbol])
            end
          end

          def expected_type_symbol
            :entity
          end

          def desugarize(sugary_type_declaration)
            Util.symbolize_keys(sugary_type_declaration)
          end

          def priority
            Priority::FIRST + 1
          end
        end
      end
    end
  end
end
