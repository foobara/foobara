module Foobara
  class CommandConnector
    class UnauthenticatedError < CommandConnectorError
      def initialize(message: "Unauthenticated", **)
        super
      end
    end
  end
end
