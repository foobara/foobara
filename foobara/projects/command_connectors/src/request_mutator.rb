module Foobara
  module CommandConnectors
    class RequestMutator < Foobara::Value::Mutator
      def inputs_type_declaration_from(_inputs_type)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def inputs_type_from(inputs_type)
        declaration = inputs_type_declaration_from(inputs_type)
        Foobara::Domain.current.foobara_type_from_declaration(declaration)
      end

      def mutate
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      alias request declaration_data
    end
  end
end
