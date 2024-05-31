module Foobara
  module CommandConnectors
    class Http < CommandConnector
      class Response < CommandConnectors::Response
        attr_accessor :headers

        def initialize(headers:, **)
          self.headers = headers
          super(**)
        end
      end
    end
  end
end
