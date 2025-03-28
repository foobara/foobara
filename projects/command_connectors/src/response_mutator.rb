module Foobara
  module CommandConnectors
    class ResponseMutator < Foobara::Value::Mutator
      def result_type_declaration_from(_result_type)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def result_type_from(result_type)
        declaration = result_type_declaration_from(result_type)
        Domain.current.foobara_type_from_declaration(declaration)
      end

      def mutate
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      alias response declaration_data
    end
  end
end
