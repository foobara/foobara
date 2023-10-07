module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def context_to_request!(path:,
                              method: nil,
                              headers: {},
                              query_string: "",
                              body: "")
        action, full_command_name = path[1..].split("/")

        if action != "run"
          # :nocov:
          raise InvalidContextError, "Not sure what to do with #{action}"
          # :nocov:
        end

        registry_entry = command_registry[full_command_name]

        unless registry_entry
          # :nocov:
          raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
          # :nocov:
        end

        self.class::Request.new(registry_entry, path:,
                                                method:,
                                                headers:,
                                                query_string:,
                                                body:)
      end
    end
  end
end
