Foobara.require_project_file("type_declarations", "type_declaration_handler")

module Foobara
  module TypeDeclarations
    module Handlers
      # TODO: we should just use the symbol instead of {type: symbol} to save space and simplify some stuff...
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          binding.pry unless sugary_type_declaration.is_a?(TypeDeclaration)

          strict_type_declaration = if sugary_type_declaration.strict?
                                      sugary_type_declaration
                                    else
                                      desugarize(TypeDeclaration.new(sugary_type_declaration.declaration_data))
                                    end

          return false unless strict_type_declaration.is_a?(::Hash)

          # we only handle case where it's a builtin type not an extension of one
          if strict_type_declaration.keys == [:type]
            type_symbol = strict_type_declaration[:type]
            if type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)
              type_registered?(type_symbol)
            end
          end.tap do |applicable|
            if applicable && !sugary_type_declaration.equal?(strict_type_declaration)
              sugary_type_declaration.assign(strict_type_declaration)
            end
          end
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
