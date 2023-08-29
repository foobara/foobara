module Foobara
  module TypeDeclarations
    module WithRegistries
      extend ActiveSupport::Concern

      class_methods do
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

      delegate :type_for_declaration,
               :type_declaration_handler_for,
               :type_for_symbol,
               :type_registered?,
               to: :class
    end
  end
end
