Foobara.require_file("type_declarations", "type_declaration_handler")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          strict_type_declaration = desugarize(sugary_type_declaration)

          return false unless strict_type_declaration.is_a?(::Hash)

          # we only handle case where it's a builtin type not an extension of one
          if strict_type_declaration.keys == [:type]
            type_symbol = strict_type_declaration[:type]
            type_registered?(type_symbol)
          end
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
