module Foobara
  module Types
    class TypeDeclarationHandler < Value::Processor
      class BuiltinAtomTypeDeclarationHandler < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class SymbolDesugarizer < Value::Transformer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.is_a?(Symbol)
          end

          def transform(symbol)
            { type: symbol }
          end
        end
      end
    end
  end
end
