module Foobara
  module Manifest
    # TODO: override new to return Entity when it's an entity
    class Type < BaseManifest
      self.category_symbol = :type

      class << self
        def new(root_manifest, path)
          type = super

          if self == Type
            if type.entity?
              type = Entity.new(type.root_manifest, type.path)
            elsif type.detached_entity?
              type = DetachedEntity.new(type.root_manifest, type.path)
            elsif type.model?
              type = Model.new(type.root_manifest, type.path)
            end
          end

          type
        end
      end

      def type_manifest
        relevant_manifest
      end

      def entity?
        !builtin? && extends_symbol?(:entity)
      end

      def detached_entity?
        !builtin? && extends_symbol?(:detached_entity)
      end

      def model?
        !builtin? && extends_symbol?(:model)
      end

      def base_type
        base_type_symbol = self[:base_type]

        if base_type_symbol
          Type.new(root_manifest, [:type, self[:base_type]])
        end
      end

      def target_class
        if target_classes.size != 1
          # :nocov:
          raise "Can only use #target_class for types with one target class but #{name} has #{target_classes.size}"
          # :nocov:
        end

        target_classes.first
      end

      def types_depended_on
        @types_depended_on ||= self[:types_depended_on].map do |type_reference|
          Type.new(root_manifest, [:type, type_reference])
        end
      end

      def type_name
        scoped_name
      end

      def full_type_name
        scoped_full_name
      end

      def builtin?
        BuiltinTypes.builtin_reference?(reference)
      end

      # Not sure the best way to define this...
      def custom?
        !builtin? && !model?
      end

      def extends_symbol?(symbol)
        type = base_type

        while type
          return true if type.reference.to_sym == symbol

          type = type.base_type
        end

        false
      end

      def to_type_declaration_from_declaration_data
        TypeDeclaration.new(root_manifest, [*path, :declaration_data])
      end
    end
  end
end
