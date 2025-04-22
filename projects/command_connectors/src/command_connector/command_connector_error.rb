module Foobara
  class CommandConnector
    class CommandConnectorError < Foobara::RuntimeError
      context({})

      def initialize(message:, context: {})
        super
      end
    end
  end
end
