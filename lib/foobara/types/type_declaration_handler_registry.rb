module Foobara
  module Types
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
