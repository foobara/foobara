module Foobara
  module TypeDeclarations
    module WithRegistries
      include Concern

      module ClassMethods
        def type_for_declaration(...)
          TypeBuilder.current.type_for_declaration(...)
        end

        def type_declaration_handler_for(...)
          TypeBuilder.current.type_declaration_handler_for(...)
        end

        def type_for_symbol(symbol)
          Foobara::Namespace.current.foobara_lookup_type!(symbol)
        end

        def type_registered?(...)
          TypeBuilder.current.type_registered?(...)
        end

        def handler_for_class(...)
          TypeBuilder.current.handler_for_class(...)
        end
      end

      foobara_delegate :type_for_declaration,
                       :type_declaration_handler_for,
                       :type_for_symbol,
                       :type_registered?,
                       :handler_for_class,
                       to: :class
    end
  end
end
