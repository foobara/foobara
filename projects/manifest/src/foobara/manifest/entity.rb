require_relative "model"

module Foobara
  module Manifest
    class Entity < DetachedEntity
      # this isn't inherited? why not?
      self.category_symbol = :type

      alias entity_manifest model_manifest

      def has_associations?
        associations && !associations.empty?
      end

      def full_entity_name
        full_model_name
      end

      # TODO: should this instead be on DetachedEntity??
      def associations
        @associations ||= self[:associations].to_h do |path_key, type_name|
          [path_key.to_sym, Type.new(root_manifest, [:type, type_name])]
        end
      end
    end
  end
end
