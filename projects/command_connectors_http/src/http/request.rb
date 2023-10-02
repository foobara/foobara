module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class UnknownError < StandardError; end
      class NotFoundError < StandardError; end
      class UnauthenticatedError < StandardError; end
      class UnauthorizedError < StandardError; end

      class Request < Foobara::CommandConnector::Request
        attr_accessor :path,
                      :query_string,
                      :method,
                      :body,
                      :headers

        def initialize(registry_entry, path: nil, method: nil, headers: nil, query_string: nil, body: nil)
          self.path = path[1..]
          self.query_string = query_string
          self.method = method
          self.body = body
          self.headers = headers

          super(registry_entry)
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

        # TODO: how to transform into body + headers headers cleanly?? Maybe subclass of Outcome?
        def response
          @response ||= begin
            if outcome.success?
              body = JSON.fast_generate(outcome.result)
              status = 200
            else
              body = JSON.fast_generate(outcome.errors_hash)

              errors = outcome.errors

              status = if errors.size == 1
                         error = errors.first

                         case error
                         when UnknownError
                           500
                         when NotFoundError
                           404
                         when UnauthenticatedError
                           401
                         when UnauthorizedError
                           403
                         end
                       end || 422
            end

            Response.new(status, {}, body)
          end
        end
      end
    end
  end
end
