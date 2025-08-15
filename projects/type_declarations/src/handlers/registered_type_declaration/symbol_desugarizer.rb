Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class SymbolDesugarizer < TypeDeclarations::Desugarizer
          # TODO: we should always be applicable if it's a symbol or string and treat it as
          # a reference instead of allowing more complex custom types to be expressed as
          # strings/symbols and they could also register a higher-priority handler
          # if needed
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.symbol?
              # TODO: let's find the type and save it on the declaration to save calls elsewhere
              # since lookups and checking if registered are equally expensive
              type_registered?(sugary_type_declaration.declaration_data)
            elsif sugary_type_declaration.string? && TypeDeclarations.stringified?
              type_registered?(sugary_type_declaration.declaration_data.to_sym)
            end
          end

          def desugarize(sugary_type_declaration)
            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            sugary_type_declaration.declaration_data = { type: sugary_type_declaration.declaration_data.to_sym }

            sugary_type_declaration
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
