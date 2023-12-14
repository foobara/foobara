Foobara.require_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class SymbolDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.is_a?(Symbol) && type_registered?(sugary_type_declaration)
          end

          def desugarize(symbol)
            type = type_for_symbol(symbol)

            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            { type: type.foobara_manifest_reference.to_sym }
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
