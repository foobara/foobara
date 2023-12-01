require_relative "type"

module Foobara
  module Manifest
    class Entity < Type
      def entity_manifest
        relevant_manifest
      end

      def attributes_type
        Attributes.new(root_manifest, [*path, :attributes_type])
      end
    end
  end
end
