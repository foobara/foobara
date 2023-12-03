module Foobara
  class Namespace
    class BaseRegistry
      def register(scoped)
        raise "Subclass responsibility"
      end

      def lookup(path,  filter: nil)
        raise "Subclass responsibility"
      end

      def each_scoped(&)
        raise "Subclass responsibility"
      end

      def apply_filter(object, filter)
        if filter
          if object.is_a?(::Array)
            object.select { |o| o.instance_eval(filter) }
          elsif object&.instance_eval(filter)
            object
          end
        else
          object
        end
      end
    end
  end
end
