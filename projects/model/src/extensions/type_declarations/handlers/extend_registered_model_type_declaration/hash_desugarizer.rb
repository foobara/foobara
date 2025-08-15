module Foobara
  module TypeDeclarations
    module Handlers
      # TODO: Can't we just delete this type entirely?
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.hash?

            type_symbol = sugary_type_declaration[:type]

            if type_symbol.is_a?(::Symbol)
              # TODO: cache this on a #base_type= helper
              type = sugary_type_declaration.type || lookup_type(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)

              type&.extends?(BuiltinTypes[expected_type_symbol])
            end
          end

          def expected_type_symbol
            :model
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!
          end

          def priority
            Priority::HIGH
          end
        end
      end
    end
  end
end
