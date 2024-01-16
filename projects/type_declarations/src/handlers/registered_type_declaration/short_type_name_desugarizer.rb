Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ShortTypeNameDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(Hash) && sugary_type_declaration.key?(:type)
              type_symbol = sugary_type_declaration[:type]

              type_symbol.is_a?(::Symbol) && type_registered?(sugary_type_declaration[:type])
            end
          end

          def desugarize(sugary_type_declaration)
            type = type_for_symbol(sugary_type_declaration[:type])

            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            sugary_type_declaration[:type] = type.foobara_manifest_reference.to_sym

            sugary_type_declaration
          end
        end
      end
    end
  end
end
