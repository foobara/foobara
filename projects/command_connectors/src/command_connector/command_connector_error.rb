module Foobara
  class CommandConnector
    class CommandConnectorError < Foobara::RuntimeError
      context({})

      def initialize(message:, symbol: nil, context: {})
        super
      end
    end
  end
end
