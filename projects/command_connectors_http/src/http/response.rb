module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class Response < CommandConnectors::Response
        attr_accessor :headers

        def initialize(headers:, **opts)
          self.headers = headers
          super(**opts)
        end
      end
    end
  end
end
