module Foobara
  require_file("command_connectors", "serializer")

  module CommandConnectors
    class ErrorsSerializer < Serializer
      # TODO: always_applicable? instead?
      def always_applicable?
        !request.outcome.success?
      end

      def serialize(errors)
        ErrorCollection.to_h(errors)
      end
    end
  end
end
