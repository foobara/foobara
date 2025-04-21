require_relative "command_connector_error"

module Foobara
  class CommandConnector
    class NotFoundError < CommandConnectorError
      class << self
        def context_type_declaration
          { not_found: :string }
        end
      end

      attr_accessor :not_found

      def initialize(not_found)
        self.not_found = not_found

        super(message, context: { not_found: })
      end

      def message
        "Not found: #{not_found}"
      end
    end
  end
end
