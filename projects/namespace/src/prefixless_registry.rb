require_relative "base_registry"

module Foobara
  class Namespace
    class PrefixlessRegistry < BaseRegistry
      class RegisteringScopedWithPrefixError < StandardError; end

      def registry
        @registry ||= {}
      end

      def register(scoped)
        if scoped.scoped_prefix
          raise RegisteringScopedWithPrefixError,
                "Cannot register scoped with a prefix: #{scoped.scoped_name.inspect}"
        end

        registry[scoped.scoped_short_name] = scoped
      end

      def lookup(path, filter = nil)
        apply_filter(registry[path.first], filter)
      end

      def each_scoped(&)
        registry.each_value(&)
      end
    end
  end
end
