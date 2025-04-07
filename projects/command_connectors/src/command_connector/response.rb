module Foobara
  class CommandConnector
    class Response
      attr_accessor :request,
                    :status,
                    :body

      def initialize(request:, status: nil, body: nil)
        self.request = request
        self.status = status
        self.body = body
      end

      def command
        request.command
      end

      def success?
        request.success?
      end
    end
  end
end
