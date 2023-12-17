module Foobara
  require_file("command_connectors", "serializer")

  module CommandConnectors
    class SuccessSerializer < Serializer
      # TODO: always_applicable? instead?
      def always_applicable?
        request.outcome.success?
      end
    end
  end
end
