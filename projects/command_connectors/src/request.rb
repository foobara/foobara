module Foobara
  module CommandConnectors
    class Request
      # TODO: this feels like a smell of some sort...
      attr_accessor :command_class, :command, :error, :command_connector

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
