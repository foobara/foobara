module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class Request < Foobara::CommandConnector::Request
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
          # raise # uncomment when debugging. TODO: figure out how to make this not necessary
          # TODO: move to superclass?
          self.outcome = Outcome.error(CommandConnector::UnknownError.new(e))
        end
      end
    end
  end
end
