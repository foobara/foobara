module Foobara
  module TypeDeclarations
    class TypeDeclarationHandlerRegistry < Value::SelectionProcessor
      def applicable?(_value)
        true
      end

      def always_applicable?
        true
      end
    end
  end
end
