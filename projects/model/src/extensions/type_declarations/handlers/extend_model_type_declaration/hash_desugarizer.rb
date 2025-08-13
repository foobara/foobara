module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class HashDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false unless sugary_type_declaration.hash?
            return false unless sugary_type_declaration.all_symbolizable_keys?

            type_symbol = sugary_type_declaration[:type]
            if type_symbol
              if type_symbol.is_a?(::String)
                type_symbol = type_symbol.to_sym
              end
              return true if type_symbol == expected_type_symbol
            end

            type_symbol = sugary_type_declaration["type"]
            return true if type_symbol.nil?

            if type_symbol.is_a?(::String)
              type_symbol = type_symbol.to_sym
            end

            type_symbol == expected_type_symbol
          end

          def expected_type_symbol
            :model
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!
            sugary_type_declaration
          end

          def priority
            Priority::HIGH
          end
        end
      end
    end
  end
end
