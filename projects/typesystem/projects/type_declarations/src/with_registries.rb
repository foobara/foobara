require "foobara/concerns"

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

        def lookup_type(...)
          Foobara::Namespace.current.foobara_lookup_type(...)
        end

        def type_registered?(...)
          Foobara::Namespace.current.foobara_type_registered?(...)
        end

        def handler_for_class(...)
          Domain.current.foobara_type_builder.handler_for_class(...)
        end
      end

      def type_for_declaration(...)
        self.class.type_for_declaration(...)
      end

      def type_declaration_handler_for(...)
        self.class.type_declaration_handler_for(...)
      end

      def lookup_type(...)
        self.class.lookup_type(...)
      end

      def lookup_type!(...)
        self.class.lookup_type!(...)
      end

      def lookup_absolute_type!(...)
        self.class.lookup_absolute_type!(...)
      end

      def type_registered?(...)
        self.class.type_registered?(...)
      end

      def handler_for_class(...)
        self.class.handler_for_class(...)
      end
    end
  end
end
