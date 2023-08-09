require "foobara/type/type_error"

module Foobara
  class Type < Value::Processor
    class CannotCastError < Foobara::Type::TypeError
      def initialize(**opts)
        super(**opts.merge(symbol: :cannot_cast))
      end
    end
  end
end
