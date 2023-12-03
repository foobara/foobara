module Foobara
  class Namespace
    class PrefixlessRegistry
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

      def lookup(path)
        registry[path.first]
      end
    end
  end
end
