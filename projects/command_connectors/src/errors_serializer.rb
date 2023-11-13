module Foobara
  require_file("command_connectors", "serializer")

  module CommandConnectors
    class ErrorsSerializer < Serializer
      # TODO: always_applicable? instead?
      def always_applicable?
        !request.outcome.success?
      end

      def serialize(errors)
        errors.map(&:to_h)
      end
    end
  end
end
