module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def context_to_request!(path:, method: nil, headers: {}, query_string: "", body: "")
        registry_entry = nil
        original_context = nil

        action, full_command_name = path[1..].split("/")

        case action
        when "run"
          registry_entry = command_registry[full_command_name]

          unless registry_entry
            # :nocov:
            raise NoCommandFoundError,
                  "Could not find command registered for #{full_command_name}"
            # :nocov:
          end
        when "describe"
          command_to_describe = full_command_name

          command_class = Foobara::CommandConnectors::DescribeCommand
          full_command_name = command_class.full_command_name

          # TODO: URL encode?
          param = "command=#{command_to_describe}"
          query_string = if query_string.empty?
                           param
                         else
                           "#{query_string}&#{param}"
                         end
          path = "/run/#{full_command_name}"
          registry_entry = command_registry[full_command_name] || build_registry_entry(command_class)
          original_context = { path:, method:, headers:, query_string:, body: }
        else
          # :nocov:
          raise InvalidContextError, "Not sure what to do with #{action}"
          # :nocov:
        end

        # TODO: why not pass the command_class to the request?
        self.class::Request.new(registry_entry, path:,
                                                method:,
                                                headers:,
                                                query_string:,
                                                body:,
                                                original_context:)
      end
    end
  end
end
