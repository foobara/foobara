module Foobara
  module Connectors
    class Http < CommandConnector
      class Request
        attr_accessor :path,
                      :query_string,
                      :method,
                      :body,
                      :headers,
                      :action,
                      :command

        def initialize(path, method, headers, query_string, body)
          self.path = path[1..]
          self.query_string = query_string
          self.method = method
          self.body = body
          self.headers = headers

          action, command_name = self.path.split("/")

          self.action = action
          self.command_name = command_name
        end

        def inputs
          @inputs ||= begin
            body_inputs = body.empty? ? {} : JSON.parse(body)
            query_string_inputs = query_string.empty? ? {} : ::Rack::Utils.parse_nested_query(query_string)

            body_inputs.merge(query_string_inputs)
          end
        end
      end
    end
  end
end
