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

    def command_manifest
      h = {}

      # TODO: should group by org and domain...
      command_registry.registry.values.map(&:manifest).each do |manifest|
        organization_name = manifest[:organization_name] || :global_organization
        domain_name = manifest[:domain_name] || :global_domain
        command_name = manifest[:command_name]

        org = h[organization_name.to_sym] ||= {}
        domain = org[domain_name.to_sym] ||= {}

        domain[command_name.to_sym] = manifest
      end

      h
    end
  end
end
