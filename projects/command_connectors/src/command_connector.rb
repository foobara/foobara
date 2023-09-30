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

      def run(command_name, inputs)
        registry_entry = command_registry[command_name]

        unless registry_entry
          raise "No command class registered for #{command_name}"
        end

        command_class = registry_entry.command_class
        command = command_class.new(inputs)

        command.run
      end
    end
  end
end
