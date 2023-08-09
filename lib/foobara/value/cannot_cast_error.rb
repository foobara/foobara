require "foobara/value/error"

module Foobara
  module Value
    class CannotCastError < Value::Error
      def initialize(**opts)
        super(**opts.merge(symbol: :cannot_cast))
      end
    end
  end
end
