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

    class UnauthenticatedError < CommandConnectorError
      def initialize
        super("Unauthenticated")
      end
    end

    class NotAllowedError < CommandConnectorError; end

    foobara_delegate :add_default_inputs_transformer,
                     :add_default_result_transformer,
                     :add_default_errors_transformer,
                     :allowed_rule,
                     :allowed_rules,
                     to: :command_registry

    attr_accessor :command_registry, :authenticator

    def initialize(authenticator: nil)
      self.authenticator = authenticator
      self.command_registry = CommandRegistry.new(authenticator:)
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
