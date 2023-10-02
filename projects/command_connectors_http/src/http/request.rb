module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class Request < Foobara::CommandConnector::Request
        attr_accessor :path,
                      :query_string,
                      :method,
                      :body,
                      :headers,
                      :action,
                      :full_command_name

        def initialize(registry, path:, method:, headers: nil, query_string: nil, body: nil)
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
          @untransformed_inputs ||= parsed_body.merge(parsed_query_string)
        end

        def parsed_body
          body.nil? || body.empty? ? {} : JSON.parse(body)
        end

        def parsed_query_string
          @parsed_query_string ||= if query_string.nil? || query_string.empty?
                                     {}
                                   else
                                     CGI.parse(query_string).transform_values!(&:first)
                                   end
        end
      end
    end
  end
end
