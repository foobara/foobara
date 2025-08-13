Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class SymbolDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(::Symbol)
              type_registered?(sugary_type_declaration)
            elsif sugary_type_declaration.is_a?(::String) && TypeDeclarations.stringified?
              applicable?(sugary_type_declaration.to_sym)
            end
          end

          def desugarize(symbol)
            symbol = if TypeDeclarations.strict?
                       symbol
                     elsif TypeDeclarations.strict_stringified?
                       symbol.to_sym
                     else
                       lookup_type!(type_symbol).full_type_symbol
                     end

            TypeDeclaration.new(symbol)
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
