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
    end
  end
end
