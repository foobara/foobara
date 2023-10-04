module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def context_to_request(**context)
        path = context[:path]

        action, full_command_name = path[1..].split("/")

        if action != "run"
          # :nocov:
          raise "Not sure what to do with #{action}"
          # :nocov:
        end

        registry_entry = command_registry[full_command_name]

        unless registry_entry
          # :nocov:
          raise "Could not find command registered for #{path}"
          # :nocov:
        end

        self.class::Request.new(registry_entry, **context)
      end
    end
  end
end
