module Foobara
  module TypeDeclarations
    module WithRegistries
      include Concern

      module ClassMethods
        def type_for_declaration(...)
          Domain.current.foobara_type_from_declaration(...)
        end

        def type_declaration_handler_for(...)
          Domain.current.foobara_type_builder.type_declaration_handler_for(...)
        end

        def lookup_type!(...)
          Foobara::Namespace.current.foobara_lookup_type!(...)
        end

        def type_registered?(...)
          Foobara::Namespace.current.foobara_type_registered?(...)
        end

        def handler_for_class(...)
          Domain.current.foobara_type_builder.handler_for_class(...)
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
