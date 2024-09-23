module Foobara
  module CommandConnectors
    class Http < Foobara::CommandConnector
      module Commands
        class Describe < Foobara::CommandConnectors::Commands::Describe
          def stamp_request_metadata
            manifest[:metadata] = super.merge(url: request.url)
          end
        end
      end
    end
  end
end
