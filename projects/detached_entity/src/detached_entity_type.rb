module Foobara
  class DetachedEntityType < Types::Type
    class << self
      def types_requiring_conversion
        @types_requiring_conversion ||= Set.new
      end

      def model_base_classes_requiring_conversion
        @model_base_classes_requiring_conversion ||= Set.new
      end

      def type_requires_conversion?(type)
        types_requiring_conversion.include?(type)
      end

      def model_base_class_requires_conversion?(model_base_class)
        model_base_classes_requiring_conversion.include?(model_base_class)
      end
    end

    def foobara_manifest(to_include: Set.new, remove_sensitive: false)
      manifest = super

      if detached_context?
        declaration_data = manifest[:declaration_data]
        if self.class.type_requires_conversion?(declaration_data[:type])
          declaration_data = declaration_data.merge(type: :detached_entity)
        end

        if self.class.model_base_class_requires_conversion?(declaration_data[:model_base_class])
          declaration_data = declaration_data.merge(model_base_class: "Foobara::DetachedEntity")
        end

        manifest = manifest.merge(declaration_data:)
      end

      manifest
    end

    def types_to_add_to_manifest
      types = super

      if detached_context?
        types.delete(base_type)
        types.unshift(base_type_for_manifest)
      end

      types
    end

    def base_type_for_manifest
      if detached_context?
        BuiltinTypes[:detached_entity]
      else
        super
      end
    end

    def detached_context?
      Thread.foobara_var_get("foobara_manifest_context")&.[](:detached)
    end
  end
end
