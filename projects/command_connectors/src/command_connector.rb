module Foobara
  module CommandConnectors
    class CommandConnector
      attr_accessor :command_registry

      def initialize
        self.command_registry = CommandRegistry.new
      end

      def connect(...)
        command_registry.register(...)
      end

      def run(...)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def context_to_request(...)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def run_for_context(...)
        request = context_to_request(...)
        run_request(request)
        request
      end

      def run_request(request)
        request.run
      end
    end
  end
end
