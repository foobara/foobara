module Foobara
  module Types
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class RegisteredTypeDeclarationHandler < TypeDeclarationHandler
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
