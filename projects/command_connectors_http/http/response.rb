module Foobara
  module Connectors
    class Http < CommandConnector
      class Response
        attr_accessor :status,
                      :headers,
                      :body

        def initialize(status, headers, body)
          self.status = status
          self.headers = headers
          self.body = body
        end
      end
    end
  end
end
