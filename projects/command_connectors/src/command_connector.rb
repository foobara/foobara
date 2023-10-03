module Foobara
  class CommandConnector
    class CommandConnectorError < Foobara::RuntimeError
      class << self
        def context_type_declaration
          {}
        end
      end

      def initialize(message)
        super(message:, context: {})
      end
    end

    class UnknownError < CommandConnectorError
      attr_accessor :error

      def initialize(error)
        # TODO: can we just use #cause for this?
        self.error = error

        super(error.message)
      end
    end

    class NotFoundError < CommandConnectorError; end
    class UnauthenticatedError < CommandConnectorError; end
    class NotAllowedError < CommandConnectorError; end

    attr_accessor :command_registry

    def initialize
      self.command_registry = CommandRegistry.new
    end

    def connect(...)
      command_registry.register(...)
    end

    def context_to_request(...)
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end

    def run(...)
      request = context_to_request(...)
      request.run
      request
    end
  end
end
