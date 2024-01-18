module Foobara
  class Namespace
    include IsNamespace

    class << self
      attr_accessor :global

      def current
        Thread.current[:foobara_current_namespace] || global
      end

      # TODO: eliminate deprecated_namespace and yield instead
      def use(namespace, deprecated_namespace, &)
        unless namespace.is_a?(Namespace::IsNamespace)
          # :nocov:
          raise ArgumentError, "Expected #{namespace} to be a namespace"
          # :nocov:
        end

        old_namespace = current

        if old_namespace == namespace
          TypeDeclarations::Namespace.using(deprecated_namespace, &)
        else
          begin
            Thread.current[:foobara_current_namespace] = namespace
            TypeDeclarations::Namespace.using(deprecated_namespace, &)
          ensure
            Thread.current[:foobara_current_namespace] = old_namespace
          end
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
