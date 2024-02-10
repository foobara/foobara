require_relative "type"

module Foobara
  module Manifest
    class Model < Type
      self.category_symbol = :type

      alias model_manifest relevant_manifest

      def attributes_type
        Attributes.new(root_manifest, [*path, :attributes_type])
      end

      def attribute_names
        attributes_type.attribute_names
      end
    end
  end
end
