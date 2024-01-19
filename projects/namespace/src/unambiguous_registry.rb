require_relative "base_registry"

module Foobara
  class Namespace
    class UnambiguousRegistry < BaseRegistry
      def registry
        @registry ||= {}
      end

      def register(scoped)
        new_entries = {}

        to_keys(scoped).each do |key|
          if registry.key?(key)
            raise WouldMakeRegistryAmbiguousError,
                  "Ambiguous match for #{key.inspect}. Matches the following: #{registry[key].inspect}"
          end

          new_entries[key] = scoped
        end

        registry.merge!(new_entries)
      end

      def unregister(scoped)
        to_keys(scoped).each do |key|
          unless registry.key?(key)
            raise NotRegisteredError, "Not registered: #{key.inspect}"
          end

          registry.delete(key)
        end
      end

      def lookup(path, filter = nil)
        apply_filter(registry[path], filter)
      end

      def each_scoped_without_filter(&)
        registry.each_value(&)
      end

      # TODO: why don't we do this in UnambiguousRegistry??
      def to_keys(scoped)
        short_name = scoped.scoped_short_name
        prefixes = scoped.scoped_prefix ? Util.power_set(scoped.scoped_prefix) : [[]]

        prefixes.map do |prefix|
          [*prefix, short_name]
        end
      end
    end
  end
end
