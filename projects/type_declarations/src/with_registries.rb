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

        def lookup_type!(...)
          Foobara::Namespace.current.foobara_lookup_type!(...)
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
                       :lookup_type!,
                       :type_registered?,
                       :handler_for_class,
                       to: :class
    end
  end
end
