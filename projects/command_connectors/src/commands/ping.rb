module Foobara
  module CommandConnectors
    module Commands
      class Ping < Foobara::Command
        result pong: :datetime

        def execute
          pong
        end

        def pong
          response = { pong: Time.now }

          sha1 = ENV.fetch("GIT_SHA1", nil)

          if sha1
            response[:git_sha1] = sha1
          end

          response
        end
      end
    end
  end
end
