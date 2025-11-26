module Foobara
  class Namespace
    include IsNamespace

    class << self
      def global
        @global ||= Namespace.new([])
      end

      def current
        Thread.current[:foobara_current_namespace] || global
      end

      def use(namespace)
        unless namespace.is_a?(Namespace::IsNamespace)
          # :nocov:
          raise ArgumentError, "Expected #{namespace} to be a namespace"
          # :nocov:
        end

        old_namespace = current

        if old_namespace == namespace
          yield
        else
          begin
            Thread.current[:foobara_current_namespace] = namespace
            yield
          ensure
            Thread.current[:foobara_current_namespace] = old_namespace
          end
        end
      end

      def to_registry_path(object)
        return object.map(&:to_s) if object.is_a?(::Array)

        object = object.to_s if object.is_a?(::Symbol)

        case object
        when ::String
          # TODO: Why don't we use symbols instead of strings here?
          object.split("::")
        when Foobara::Scoped
          object.scoped_path
        else
          # :nocov:
          raise ArgumentError, "Expected #{object} to be a string, symbol, array, or Foobara::IsScoped"
          # :nocov:
        end
      end

      def on_change(object, method_name)
        @on_change ||= ObjectSpace::WeakMap.new

        @on_change[object] = method_name
      end

      def fire_changed!
        @on_change&.each_pair do |object, method_name|
          object.send(method_name)
        end
      end

      def lru_cache
        @lru_cache ||= Foobara::LruCache.new(1000)
      end

      def clear_lru_cache!
        @lru_cache&.reset!
      end
    end

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path = nil, parent_namespace: nil)
      NamespaceHelpers.initialize_foobara_namespace(self, scoped_name_or_path, parent_namespace:)
    end
  end
end
