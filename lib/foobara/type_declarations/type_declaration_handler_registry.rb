module Foobara
  module TypeDeclarations
    class TypeDeclarationHandlerRegistry < Value::Processor::Selection
      def applicable?(_value)
        true
      end

      def always_applicable?
        true
      end

      def type_declaration_handler_for(type_declaration)
        processor_for!(type_declaration)
      end

      def type_for(type_declaration)
        process!(type_declaration)
      end
    end
  end
end
