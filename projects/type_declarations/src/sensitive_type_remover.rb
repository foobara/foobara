module Foobara
  module TypeDeclarations
    class SensitiveTypeRemover < Value::Transformer
      def applicable?(strict_type_declaration)
        handler.applicable?(strict_type_declaration)
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
