Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ShortTypeNameDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            return false if sugary_type_declaration.strict? || sugary_type_declaration.strict_stringified?
            return false unless sugary_type_declaration.hash?
            return false if sugary_type_declaration.absolutified?

            type_symbol = if sugary_type_declaration.key?(:type)
                            sugary_type_declaration[:type]
                          elsif sugary_type_declaration.key?("type")
                            sugary_type_declaration["type"]
                          end

            if type_symbol
              if type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)
                type = sugary_type_declaration.type || lookup_type(type_symbol)

                if type
                  # cheating and doing this here to save a lookup
                  sugary_type_declaration.symbolize_keys!
                  sugary_type_declaration[:type] = type.full_type_symbol
                  sugary_type_declaration.is_absolutified = true

                  true
                end
              end
            end
          end

          def desugarize(sugary_type_declaration)
            # We cheated and applied this in applicable? to save a lookup

            sugary_type_declaration
          end

          def priority
            Priority::FIRST + 2
          end
        end
      end
    end
  end
end
