module Foobara
  module Manifest
    class Type < BaseManifest
      def type_manifest
        relevant_manifest
      end

      def entity?
        base_type == "entity"
      end
    end
  end
end
