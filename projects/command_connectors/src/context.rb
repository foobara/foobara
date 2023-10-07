module Foobara
  module CommandConnectors
    class Context
      def full_command_name
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def inputs
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end
    end
  end
end
