require_relative "model"

module Foobara
  module Manifest
    class DetachedEntity < Model
      # this isn't inherited? why not?
      self.category_symbol = :type

      optional_key(:associations, default: {})

      alias detached_entity_manifest model_manifest

      def primary_key_name
        primary_key_attribute.to_s
      end

      def primary_key_type
        @primary_key_type ||= TypeDeclaration.new(root_manifest, [*manifest_path, :primary_key_type])
      end

      def attribute_names
        super - [primary_key_name]
      end

      def full_detached_entity_name
        full_model_name
      end
    end
  end
end
