require_relative "model"

module Foobara
  module Manifest
    # TODO: add a DetachedEntity class to Manifest and inherit from it
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

      def full_entity_name
        full_model_name
      end

      def associations
        @associations ||= self[:associations].to_h do |path_key, type_name|
          [path_key.to_sym, Type.new(root_manifest, [:type, type_name])]
        end
      end
    end
  end
end
