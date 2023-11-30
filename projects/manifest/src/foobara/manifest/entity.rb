require_relative "type"

module Foobara
  module Manifest
    class Entity < Type
      def entity_manifest
        relevant_manifest
      end
    end
  end
end
