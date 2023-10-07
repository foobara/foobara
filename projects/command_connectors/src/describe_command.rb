module Foobara
  module CommandConnectors
    class DescribeCommand < Foobara::Command
      inputs full_command_name: :string,
             command_registry: :duck
      result :associative_array

      def execute
        find_registry_entry
        build_manifest
      end

      attr_accessor :registry_entry

      def find_registry_entry
        self.registry_entry = command_registry[full_command_name]
        # TODO: add error if we don't find the entry
      end

      def build_manifest
        registry_entry.manifest
      end
    end
  end
end
