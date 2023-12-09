require_relative "base_registry"

module Foobara
  class Namespace
    class UnambiguousRegistry < BaseRegistry
      def registry
        @registry ||= {}
      end

      def register(scoped)
        short_name = scoped.scoped_short_name
        prefixes = scoped.scoped_prefix ? Util.power_set(scoped.scoped_prefix) : [[]]

        new_entries = {}

        prefixes.each do |prefix|
          key = [*prefix, short_name]

          if registry.key?(key)
            raise WouldMakeRegistryAmbiguousError,
                  "Ambiguous match for #{key.inspect}. Matches the following: #{registry[key].inspect}"
          end

          new_entries[key] = scoped
        end

        registry.merge!(new_entries)
      end

      def lookup(path, filter = nil)
        apply_filter(registry[path], filter)
      end

      def each_scoped_without_filter(&)
        registry.each_value(&)
      end
    end
  end
end
