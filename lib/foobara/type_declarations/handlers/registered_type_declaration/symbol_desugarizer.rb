require "foobara/type_declarations/desugarizer"

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class SymbolDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.is_a?(Symbol)
          end

          def desugarize(symbol)
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