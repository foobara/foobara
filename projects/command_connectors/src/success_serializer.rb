module Foobara
  require_file("command_connectors", "serializer")

  module CommandConnectors
    class SuccessSerializer < Serializer
      # TODO: always_applicable? instead?
      def applicable?(_value)
        request.outcome.success?
      end

      def serialize(object)
        transform(object)
      end
    end
  end
end
