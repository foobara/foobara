module Foobara
  class CommandConnector
    class Response
      attr_accessor :request,
                    :status,
                    :body

      # Who the request authenticated, if anyone. Nil when nothing identified a
      # caller, and also when the command asked for no authentication at all.
      def authenticated_user = request.authenticated_user

      def initialize(request:, status: nil, body: nil)
        self.request = request
        self.status = status
        self.body = body
      end

      def command
        request.command
      end

      def error
        request.error
      end

      def success?
        request.success?
      end

      def outcome
        request.outcome
      end
    end
  end
end
