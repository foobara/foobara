Foobara.require_project_file("type_declarations", "type_declaration_handler")

module Foobara
  module TypeDeclarations
    module Handlers
      # TODO: we should just use the symbol instead of {type: symbol} to save space and simplify some stuff...
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        def applicable?(sugary_type_declaration)
          return true if sugary_type_declaration.type

          unless sugary_type_declaration.reference_checked?
            sugary_type_declaration.handle_symbolic_declaration
            return true if sugary_type_declaration.type
          end

          strict_type_declaration = if sugary_type_declaration.strict?
                                      sugary_type_declaration
                                    else
                                      desugarize(sugary_type_declaration.clone)
                                    end

          return false unless strict_type_declaration.hash?

          # we only handle case where it's a builtin type not an extension of one
          if strict_type_declaration.declaration_data.keys == [:type]
            type_symbol = strict_type_declaration[:type]

            if type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)
              type = lookup_type(type_symbol)

              if type
                strict_type_declaration.type = type

                unless sugary_type_declaration.equal?(strict_type_declaration)
                  sugary_type_declaration.assign(strict_type_declaration)
                end

                true
              end
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
