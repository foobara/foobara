module Foobara
  class Manifest
    class Command < BaseManifest
      def command_manifest
        relevant_manifest
      end
    end
  end
end
