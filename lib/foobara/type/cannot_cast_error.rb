module Foobara
  class Type
    class CannotCastError < Foobara::Error
      def initialize(**opts)
        super(**opts.merge(symbol: :cannot_cast))
      end
    end
  end
end
