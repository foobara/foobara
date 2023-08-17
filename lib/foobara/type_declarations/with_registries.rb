module Foobara
  module TypeDeclarations
    module WithRegistries
      def type_for_declaration(...)
        Namespace.current.type_for_declaration(...)
      end

      def type_declaration_handler_for(...)
        Namespace.current.type_declaration_handler_for(...)
      end

      def type_for_symbol(...)
        Namespace.current.type_for_symbol(...)
      end

      def type_registered?(...)
        Namespace.current.type_registered?(...)
      end
    end
  end
end
