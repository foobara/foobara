module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        class Help < Command
          class Presenter
            class Type < Presenter
              def type_name
                scoped_full_name
              end
            end
          end
        end
      end
    end
  end
end
