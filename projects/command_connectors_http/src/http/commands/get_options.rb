module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        # TODO: this is a bit of a hack, just a total no-op... shouldn't really need this command at all ideally
        class GetOptions < Foobara::Command
          result :string

          def execute
            ""
          end
        end
      end
    end
  end
end
