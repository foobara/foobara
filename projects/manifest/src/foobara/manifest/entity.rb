module Foobara
  class Manifest
    class Entity < BaseManifest
      def entity_manifest
        relevant_manifest
      end
    end
  end
end
