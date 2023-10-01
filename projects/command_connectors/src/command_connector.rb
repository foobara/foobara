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

      def run_request(request)
        registry_entry = command_registry[request.command_name]
        registry_entry.transform_inputs(request)
        registry_entry.construct_command(request)
        registry_entry.apply_allowed_rule(request)

        command.run

        registry_entry.transform_outcome(request)

        request.outcome
      end
    end
  end
end
