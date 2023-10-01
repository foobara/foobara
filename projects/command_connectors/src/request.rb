module Foobara
  module CommandConnectors
    class Request
      attr_accessor :registry, :context

      def initialize(registry)
        self.registry = registry
      end

      def method_missing(method_name, *, **, &)
        if context_data.key?(method_name)
          context_data[method_name]
        elsif command.respond_to?(method_name)
          command.send(method_name, *, **, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, private = false)
        context_data.key?(method_name) || command.respond_to?(method_name, private) || super
      end
    end
  end
end
