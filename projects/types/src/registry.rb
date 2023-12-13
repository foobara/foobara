module Foobara
  module Types
    class Registry
      attr_accessor :name

      def initialize(name)
        self.name = name
        self.registry = {}
      end

      def [](symbol)
        unless registered?(symbol)
          # :nocov:
          raise "No type registered for symbol #{symbol.inspect}"
          # :nocov:
        end

        registry[symbol]
      end

      def register(symbol, type)
        if registry.key?(symbol)
          # :nocov:
          raise "#{symbol} was already registered"
          # :nocov:
        end

        if type.type_symbol && type.type_symbol != symbol
          # :nocov:
          raise "#{type} already has #{type.type_symbol} as its type symbol"
          # :nocov:
        end

        type.type_symbol = symbol

        registry[symbol] = type
      end

      def unregister(symbol)
        registry.delete(symbol)
      end

      def []=(symbol, type)
        register(symbol, type)
      end

      def registered?(symbol)
        registry.key?(symbol)
      end

      def all_types
        registry.values
      end

      private

      attr_accessor :registry
    end
  end
end
