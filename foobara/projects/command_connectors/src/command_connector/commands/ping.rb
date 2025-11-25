module Foobara
  class CommandConnector
    module Commands
      class Ping < Foobara::Command
        result :datetime

        def execute
          set_pong

          pong
        end

        attr_accessor :pong

        def set_pong
          self.pong = Time.now
        end
      end
    end
  end
end
