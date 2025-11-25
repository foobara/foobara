module Foobara
  class CommandConnector
    class UnknownError < CommandConnectorError
      class << self
        def for(error)
          new(message: error.message).tap do |unknown_error|
            unknown_error.error = error
          end
        end
      end

      attr_accessor :error
    end
  end
end
