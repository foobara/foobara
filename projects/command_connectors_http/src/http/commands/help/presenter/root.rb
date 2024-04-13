module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        class Help < Command
          class Presenter
            class Root < Presenter
            end
          end
        end
      end
    end
  end
end
