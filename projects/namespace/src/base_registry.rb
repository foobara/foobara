module Foobara
  class Namespace
    class BaseRegistry
      class WouldMakeRegistryAmbiguousError < StandardError; end
      class NotRegisteredError < StandardError; end

      def register(_scoped)
        # :nocov:
        raise "Subclass responsibility"
        # :nocov:
      end

      def unregister(_scoped)
        # :nocov:
        raise "Subclass responsibility"
        # :nocov:
      end

      def lookup(_path, filter: nil)
        # :nocov:
        raise "Subclass responsibility"
        # :nocov:
      end

      def each_scoped(filter: nil, &block)
        each_scoped_without_filter do |scoped|
          scoped = apply_filter(scoped, filter) if filter
          block.call(scoped) if scoped
        end
      end

      def all_scoped(filter: nil)
        all = []
        each_scoped(filter:) do |scoped|
          all << scoped
        end
        all
      end

      def each_scoped_without_filter(&)
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
