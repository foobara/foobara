module Foobara
  module CommandConnectors
    class RequestMutator < Foobara::Value::Mutator
      def inputs_type_declaration_from(_inputs_type)
        # simplecov:disable
        raise NotImplementedError
        # simplecov:enable
      end

      def inputs_type_from(inputs_type)
        declaration = inputs_type_declaration_from(inputs_type)
        Foobara::Domain.current.foobara_type_from_declaration(declaration)
      end

      def mutate
        # simplecov:disable
        raise NotImplementedError
        # simplecov:enable
      end

      alias request declaration_data
    end
  end
end
