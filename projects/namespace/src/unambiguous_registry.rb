module Foobara
  class Namespace
    class UnambiguousRegistry
      class WouldMakeRegistryAmbiguousError < StandardError; end

      def registry
        @registry ||= {}
      end

      def register(scoped)
        short_name = scoped.scoped_short_name
        prefixes = Util.power_set(scoped.scoped_prefix)

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

      def lookup(path)
        registry[path]
      end
    end
  end
end
