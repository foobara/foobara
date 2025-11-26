require_relative "command_connector_error"

module Foobara
  class CommandConnector
    class NotFoundError < CommandConnectorError
      class << self
        def for(not_found)
          if not_found
            new(context: { not_found: }, message: "Not found: #{not_found}")
          else
            new
          end
        end
      end

      context not_found: :string

      def initialize(message: nil, context: nil, **)
        if context
          not_found = context[:not_found]
          message ||= "Not found: #{not_found}"
        else
          context = {}
          message ||= "Not found"
        end

        super
      end
    end
  end
end
