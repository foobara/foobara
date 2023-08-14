module Foobara
  module Types
    class TypeDeclarationHandler < Value::Processor
      class BuiltinAtomTypeDeclarationHandler < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ToTypeTransformer < Value::Transformer
          def transform(strict_type_declaration)
            BuiltinTypes[strict_type_declaration[:type]]
          end
        end
      end
    end
  end
end
