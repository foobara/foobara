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

      foobara_delegate :command, :error, to: :request
    end
  end
end
