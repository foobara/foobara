module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def context_to_request!(path:,
                              method: nil,
                              headers: {},
                              query_string: "",
                              body: "")

        action, full_command_name = path[1..].split("/")

        registry_entry = case action
                         when "run"
                           command_registry[full_command_name]
                         else
                           # :nocov:
                           raise InvalidContextError, "Not sure what to do with #{action}"
                           # :nocov:
                         end

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
