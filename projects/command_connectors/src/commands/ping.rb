module Foobara
  module CommandConnectors
    module Commands
      class Ping < Foobara::Command
        result pong: :datetime

        def execute
          pong
        end

        def pong
          { pong: Time.now }
        end
      end
    end
  end
end
