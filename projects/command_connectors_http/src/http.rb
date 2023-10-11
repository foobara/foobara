module Foobara
  module CommandConnectors
    class Http < CommandConnector
      def request_to_command(context)
        action = context.action
        inputs = nil

        full_command_name = context.full_command_name
        transformed_command_class = command_registry[full_command_name]

        case action
        when "run"
          unless transformed_command_class
            # :nocov:
            raise NoCommandFoundError,
                  "Could not find command registered for #{full_command_name}"
            # :nocov:
          end

          inputs = context.inputs
        when "describe"
          command_class = Foobara::CommandConnectors::Commands::DescribeCommand
          full_command_name = command_class.full_command_name

          inputs = { runnable: transformed_command_class }
          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        when "ping"
          command_class = Foobara::CommandConnectors::Commands::Ping
          full_command_name = command_class.full_command_name

          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        else
          # :nocov:
          raise InvalidContextError, "Not sure what to do with #{action}"
          # :nocov:
        end

        transformed_command_class.new(inputs)
      end

      # TODO: eliminate passing the command here...
      def command_to_response(command)
        outcome = command.outcome

        # TODO: feels awkward to call this here... Maybe use result/errors transformers instead??
        # Or call the serializer here??
        body = command.serialize_result

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
  end
end
