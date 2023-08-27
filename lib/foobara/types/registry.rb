module Foobara
  module Types
    class Registry
      attr_reader :root_type

      def initialize
        self.registry = {}
      end

      def root_type=(type)
        if root_type
          # :nocov:
          raise "Already registered root type of #{root_type}"
          # :nocov:
        end

        @root_type = type
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

        registry[symbol] = type
      end

      def []=(symbol, type)
        register(symbol, type)
      end

      def registered?(symbol)
        registry.key?(symbol)
      end

      private

      attr_accessor :registry
    end
  end
end
