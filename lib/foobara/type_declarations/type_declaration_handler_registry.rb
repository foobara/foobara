module Foobara
  module TypeDeclarations
    class TypeDeclarationHandlerRegistry < Value::Processor::Selection
      def applicable?(_value)
        true
      end

      def always_applicable?
        true
      end

      def type_declaration_handler_for(value)
        processor_for(value)
      end

      def type_declaration_handler_for!(value)
        processor_for!(value)
      end
    end
  end
end
