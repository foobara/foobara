module Foobara
  class Namespace
    include IsNamespace

    class << self
      attr_accessor :global

      def current
        Thread.current[:foobara_current_namespace] || global
      end

      # TODO: eliminate deprecated_namespace and yield instead
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
        return object if object.is_a?(::Array)

        object = object.to_s if object.is_a?(::Symbol)

        case object
        when ::String
          object.split("::")
        when Foobara::Scoped
          object.scoped_path
        else
          # :nocov:
          raise ArgumentError, "Expected #{object} to be a string, symbol, array, or Foobara::IsScoped"
          # :nocov:
        end
      end
    end

    self.global = Foobara

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path = nil, parent_namespace: nil)
      NamespaceHelpers.initialize_foobara_namespace(self, scoped_name_or_path, parent_namespace:)
    end
  end
end
