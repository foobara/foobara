module Foobara
  module TypeDeclarations
    class TypeDeclarationValidator < Value::Validator
      include WithRegistries

      def always_applicable?
        true
      end
    end
  end
end
