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
            # TODO: just use the symbol and nothing else??
            # maybe confusing in languages with no distinction between symbol and string?
            { type: symbol }
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
