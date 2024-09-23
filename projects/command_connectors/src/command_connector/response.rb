module Foobara
  class CommandConnector
    class Response
      attr_accessor :status,
                    :body,
                    :request

      def initialize(status:, body:, request:)
        self.status = status
        self.body = body
        self.request = request
      end

      foobara_delegate :command, :error, to: :request
    end
  end
end
