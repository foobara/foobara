module Foobara
  module CommandConnectors
    class ResponseMutator < Foobara::Value::Mutator
      def result_type_declaration_from(_result_type)
        # simplecov:disable
        raise NotImplementedError
        # simplecov:enable
      end

      def result_type_from(result_type)
        declaration = result_type_declaration_from(result_type)
        Domain.current.foobara_type_from_declaration(declaration)
      end

      def mutate
        # simplecov:disable
        raise NotImplementedError
        # simplecov:enable
      end

      alias response declaration_data
    end
  end
end
