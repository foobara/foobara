module Foobara
  module TypeDeclarations
    class TypeDeclarationHandlerRegistry < Value::Processor::Selection
      class << self
        def foobara_manifest(to_include:)
          # :nocov:
          super.merge(processor_type: :type_declaration_handler_registry)
          # :nocov:
        end
      end

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
