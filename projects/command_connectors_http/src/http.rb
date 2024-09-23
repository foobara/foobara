module Foobara
  module CommandConnectors
    class Http < CommandConnector
      include TruncatedInspect

      def request_to_command(context)
        if context.method == "OPTIONS"
          # TODO: this feels a bit hacky and like overkill...
          return Foobara::CommandConnectors::Http::Commands::GetOptions.new
        end

        command = super

        if context.action == "help"
          # Let's unwrap the transformed command to avoid serialization
          # TODO: maybe instead register Help without serializers?
          command = command.command
        end

        command
      end

      def request_to_response(request)
        command = request.command
        outcome = command.outcome

        # TODO: feels awkward to call this here... Maybe use result/errors transformers instead??
        # Or call the serializer here??
        body = command.respond_to?(:serialize_result) ? command.serialize_result : outcome.result

        status = if outcome.success?
                   200
                 else
                   errors = outcome.errors

                   if errors.size == 1
                     error = errors.first

                     case error
                     when CommandConnector::UnknownError
                       500
                     when CommandConnector::NotFoundError, Foobara::Entity::NotFoundError
                       # TODO: we should not be coupled to Entities here...
                       body ||= "Not found"
                       404
                     when CommandConnector::UnauthenticatedError
                       401
                     when CommandConnector::NotAllowedError
                       403
                     end
                   end || 422
                 end

        headers = headers_for(request)

        Response.new(status:, headers:, body:, request:)
      end

      def headers_for(request)
        response_headers = request.response_headers

        if response_headers.nil? || !response_headers.key?("content-type")
          if request.command.respond_to?(:serialize_result)
            # TODO: we should ask the request this not the command.
            if request.command.serializers.include?(Serializers::JsonSerializer)
              response_headers = (response_headers || {}).merge("content-type" => "application/json")
            end
          end
        end

        if response_headers
          static_headers.merge(response_headers)
        else
          static_headers.dup
        end
      end

      private

      def static_headers
        @static_headers ||= ENV.each_with_object({}) do |(key, value), headers|
          match = key.match(/\AFOOBARA_HTTP_RESPONSE_HEADER_(.*)\z/)

          if match
            header_name = match[1].downcase.tr("_", "-")
            headers[header_name] = value
          end
        end.freeze
      end
    end
  end
end
