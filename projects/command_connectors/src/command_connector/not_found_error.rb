require_relative "command_connector_error"

module Foobara
  class CommandConnector
    class NotFoundError < CommandConnectorError
      context not_found: :string

      def initialize(message: "Not found: #{context[:not_found]}", **)
        super
      end
    end
  end
end
