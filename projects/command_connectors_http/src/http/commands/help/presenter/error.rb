module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        class Help < Command
          class Presenter
            class Error < Presenter
            end
          end
        end
      end
    end
  end
end
