module Foobara
  module CommandConnectors
    module Commands
      class Ping < Foobara::Command
        result pong: { type: :datetime, required: true }, git_sha1: :string

        def execute
          load_sha1
          build_pong

          pong
        end

        attr_accessor :sha1, :pong

        def load_sha1
          if File.exist?("git_sha1")
            # TODO: should instead read this off an environment variable to make it a bit more "universal?"
            self.sha1 = File.read("git_sha1").strip
          end
        end

        def build_pong
          self.pong = { pong: Time.now }

          pong[:git_sha1] = sha1 if sha1

          pong
        end
      end
    end
  end
end
