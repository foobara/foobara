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
end
