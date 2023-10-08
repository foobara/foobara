module Foobara
  module CommandConnectors
    class DescribeCommand < Foobara::Command
      inputs runnable: :duck
      result :associative_array

      def execute
        build_manifest
      end

      def build_manifest
        runnable.manifest
      end
    end
  end
end
