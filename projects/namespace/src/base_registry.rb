module Foobara
  class Namespace
    class BaseRegistry
      class WouldMakeRegistryAmbiguousError < StandardError; end

      def register(_scoped)
        # :nocov:
        raise "Subclass responsibility"
        # :nocov:
      end

      def lookup(_path, filter: nil)
        # :nocov:
        raise "Subclass responsibility"
        # :nocov:
      end

      def each_scoped(&)
        # :nocov:
        raise "Subclass responsibility"
        # :nocov:
      end

      def apply_filter(object, filter)
        if filter
          if object.is_a?(::Array)
            object.select { |o| o.instance_eval(&filter) }
          elsif object&.instance_eval(&filter)
            object
          end
        else
          object
        end
      end
    end
  end
end
