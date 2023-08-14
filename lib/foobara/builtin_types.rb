module Foobara
  module BuiltinTypes
    class << self
      # TODO: do we want a TypeRegistry class of some sort?
      def [](symbol)
        unless registered?(symbol)
          # :nocov:
          raise "No type registered for symbol #{symbol.inspect}"
          # :nocov:
        end

        registry[symbol]
      end

      def []=(symbol, type)
        if registry.key?(symbol)
          # :nocov:
          raise "#{symbol} was already registered"
          # :nocov:
        end

        registry[symbol] = type
      end

      def registered?(symbol)
        registry.key?(symbol)
      end

      private

      def registry
        @registry ||= {}
      end
    end

    [
      Schemas::Duck,
      Schemas::Symbol,
      Schemas::Integer,
      Schemas::Attributes
    ].each do |schema_class|
      schema_class.autoregister_processors
      Schema::Registry.global.register(schema_class)
    end
  end
end
