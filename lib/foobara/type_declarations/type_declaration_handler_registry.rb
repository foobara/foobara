module Foobara
  module TypeDeclarations
    class TypeDeclarationHandlerRegistry < Value::Processor::Selection
      # TODO: default these to true??
      def applicable?(_value)
        true
      end

      def always_applicable?
        true
      end

      def type_declaration_handler_for(type_declaration)
        processor_for!(type_declaration)
      end

      def type_declaration_handler_for_handler_class(type_declaration_handler_class)
        processors.find do |type_declaration_handler|
          type_declaration_handler.instance_of?(type_declaration_handler_class)
        end
      end

      def handlers
        processors
      end

      def type_for(type_declaration)
        process!(type_declaration)
      end
    end
  end
end
