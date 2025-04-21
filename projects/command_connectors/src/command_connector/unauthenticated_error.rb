module Foobara
  class CommandConnector
    class UnauthenticatedError < CommandConnectorError
      def initialize
        super("Unauthenticated")
      end
    end
  end
end
