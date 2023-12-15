module Foobara
  module Manifest
    # TODO: override new to return Entity when it's an entity
    class Type < BaseManifest
      self.category_symbol = :type

      class << self
        def new(root_manifest, path)
          type = super(root_manifest, path)

          if self == Type && type.entity?
            Entity.new(type.root_manifest, type.path)
          else
            type
          end
        end
      end

      def type_manifest
        relevant_manifest
      end

      def entity?
        base_type&.to_sym == :entity
      end

      def target_class
        if target_classes.size != 1
          # :nocov:
          raise "Can only use #target_class for types with one target class but #{name} has #{target_classes.size}"
          # :nocov:
        end

        target_classes.first
      end
    end
  end
end
