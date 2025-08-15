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
            type = if sugary_type_declaration.symbol? ||
                      (sugary_type_declaration.string? && TypeDeclarations.stringified?)
                     lookup_type(sugary_type_declaration.declaration_data)
                   end

            if type
              sugary_type_declaration.type = type

              true
            end
          end

          def desugarize(sugary_type_declaration)
            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            type = sugary_type_declaration.type

            sugary_type_declaration.declaration_data = { type: type.full_type_symbol }

            sugary_type_declaration.is_strict = true
            sugary_type_declaration.is_duped = true
            sugary_type_declaration.is_deep_duped = true

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
