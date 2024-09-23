module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class Response < CommandConnector::Response
        attr_accessor :headers

        def initialize(headers:, **)
          self.headers = headers
          super(**)
        end
      end
    end
  end
end
