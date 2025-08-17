module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.hash?
            return false unless sugary_type_declaration.all_symbolizable_keys?

            type_symbol = sugary_type_declaration[:type] || sugary_type_declaration["type"]
            return false unless type_symbol

            type_symbol = type_symbol.to_sym if type_symbol.is_a?(::String)

            return true if type_symbol == expected_type_symbol

            if type_symbol.is_a?(::Symbol)
              type = sugary_type_declaration.type ||
                     lookup_type(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)

              type&.extends?(BuiltinTypes[expected_type_symbol])
            end
          end

          def expected_type_symbol
            :detached_entity
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!
          end

          def priority
            Priority::FIRST + 1
          end
        end
      end
    end
  end
end
