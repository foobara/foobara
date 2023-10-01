module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class Request < Foobara::CommandConnector::Request
        attr_accessor :path,
                      :query_string,
                      :method,
                      :body,
                      :headers,
                      :action

        def initialize(registry, path:, method:, headers:, query_string:, body:)
          self.path = path[1..]
          self.query_string = query_string
          self.method = method
          self.body = body
          self.headers = headers

          action, full_command_name = self.path.split("/")

          self.action = action
          self.full_command_name = full_command_name

          super(registry)
        end

        def untransformed_inputs
          @untransformed_inputs ||= begin
            body_inputs = body.empty? ? {} : JSON.parse(body)
            query_string_inputs = query_string.empty? ? {} : ::Rack::Utils.parse_nested_query(query_string)

            body_inputs.merge(query_string_inputs)
          end
        end
      end
    end
  end
end
