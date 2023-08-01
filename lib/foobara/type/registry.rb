module Foobara
  class Type
    class Registry
      class AlreadyRegisteredError < StandardError; end

      def initialize
        self.types = {}
      end

      def [](symbol)
        unless registered?(symbol)
          raise ArgumentError, "No type registered for #{symbol.inspect}"
        end

        types[symbol]
      end

      def registered?(symbol)
        types.key?(symbol)
      end

      def register(symbol, type)
        if registered?(symbol)
          raise AlreadyRegisteredError, "#{symbol.inspect} is already registered!"
        end

        types[symbol] = type
      end

      private

      attr_accessor :types
    end
  end
end
