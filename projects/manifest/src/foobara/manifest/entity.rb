require_relative "model"

module Foobara
  module Manifest
    class Entity < Model
      self.category_symbol = :type

      optional_key(:associations, default: {})

      alias entity_manifest model_manifest

      def has_associations?
        associations && !associations.empty?
      end

      def primary_key_name
        primary_key_attribute.to_s
      end

      def primary_key_type
        @primary_key_type ||= TypeDeclaration.new(root_manifest, [*path, :primary_key_type])
      end

      def attribute_names
        super - [primary_key_name]
      end
    end
  end
end
