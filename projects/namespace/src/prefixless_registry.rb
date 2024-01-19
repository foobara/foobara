require_relative "base_registry"

module Foobara
  class Namespace
    class PrefixlessRegistry < BaseRegistry
      class RegisteringScopedWithPrefixError < StandardError; end

      def registry
        @registry ||= {}
      end

      def register(scoped)
        key = to_key(scoped)

        if registry.key?(key)
          raise WouldMakeRegistryAmbiguousError, "#{key} is already registered"
        end

        registry[key] = scoped
      end

      def unregister(scoped)
        key = to_key(scoped)

        unless registry.key?(key)
          # :nocov:
          raise NotRegisteredError, "#{key} is not registered"
          # :nocov:
        end

        registry.delete(key)
      end

      def lookup(path, filter = nil)
        if path.size == 1
          apply_filter(registry[path.first], filter)
        end
      end

      def each_scoped_without_filter(&)
        registry.each_value(&)
      end

      def to_key(scoped)
        if scoped.scoped_prefix
          raise RegisteringScopedWithPrefixError,
                "Cannot register scoped with a prefix: #{scoped.scoped_name.inspect}"
        end

        scoped.scoped_short_name
      end
    end
  end
end
