module Foobara
  module CommandConnectors
    class Http < CommandConnector
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

        def serialize_result
          body = if outcome.success?
                   outcome.result
                 else
                   outcome.errors_hash
                 end

          if serializer
            serializer.process_value!(body)
          else
            body
          end
        end

        # TODO: how to transform into body + headers headers cleanly?? Maybe subclass of Outcome?
        def response
          @response ||= begin
            body = serialize_result

            status = if outcome.success?
                       200
                     else
                       errors = outcome.errors

                       if errors.size == 1
                         error = errors.first

                         case error
                         when CommandConnector::UnknownError
                           500
                         when CommandConnector::NotFoundError, Foobara::Command::Concerns::Entities::NotFoundError
                           # TODO: we should not be coupled to Entities here...
                           404
                         when CommandConnector::UnauthenticatedError
                           401
                         when CommandConnector::NotAllowedError
                           403
                         end
                       end || 422
                     end

            Response.new(status, {}, body)
          end
        end

        def run
          super
        rescue => e
          # raise # uncomment when debugging
          # TODO: move to superclass?
          self.outcome = Outcome.error(CommandConnector::UnknownError.new(e))
        end
      end
    end
  end
end
