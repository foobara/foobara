module Foobara
  module CommandConnectors
    class Response
      attr_accessor :status,
                    :body,
                    :request

      def initialize(status:, body:)
        self.status = status
        self.body = body
      end
    end
  end
end
