module Foobara
  module TypeDeclarations
    class SensitiveTypeRemover < Value::Transformer
      def applicable?(strict_type_declaration)
        declaration = TypeDeclaration.new(strict_type_declaration)

        declaration.is_strict = true
        declaration.is_absolutified = true

        handler.applicable?(declaration)
      end

      def handler
        declaration_data
      end

      def remove_sensitive_types(strict_type_declaration)
        TypeDeclarations.remove_sensitive_types(strict_type_declaration)
      end
    end
  end
end
