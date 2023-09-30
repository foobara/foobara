module Foobara
  module CommandConnectors
    class CommandConnector
      attr_accessor :command_registry

      def initialize
        command_registry.new
      end

      def connect(...)
        command_registry.register(...)
      end
    end
  end
end
