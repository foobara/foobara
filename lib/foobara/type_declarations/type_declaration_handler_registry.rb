module Foobara
  module TypeDeclarations
    class TypeDeclarationHandlerRegistry < Value::Processor::Selection
      def type_declaration_handler_for_handler_class(type_declaration_handler_class)
        processors.find do |type_declaration_handler|
          type_declaration_handler.instance_of?(type_declaration_handler_class)
        end
      end

      alias type_declaration_handler_for processor_for!
      alias handlers processors
      alias type_for process_value!
    end
  end
end
