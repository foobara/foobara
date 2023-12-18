require_relative "type"

module Foobara
  module Manifest
    class Entity < Type
      self.category_symbol = :type

      alias entity_manifest relevant_manifest

      def has_associations?
        !associations.empty?
      end

      def attributes_type
        Attributes.new(root_manifest, [*path, :attributes_type])
      end

      def primary_key_name
        primary_key_attribute.to_s
      end

      def attribute_names
        attributes_type.attribute_names - [primary_key_name]
      end
    end
  end
end
