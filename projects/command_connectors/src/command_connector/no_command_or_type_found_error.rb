require_relative "not_found_error"

module Foobara
  class CommandConnector
    class NoCommandOrTypeFoundError < NotFoundError; end
  end
end
