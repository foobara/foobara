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

    def foobara_manifest
      manifest = super

      if detached_context?
        declaration_data = manifest[:declaration_data]

        if self.class.type_requires_conversion?(declaration_data[:type])
          # TODO: No longer is hit in this test suite but ActiveRecordType needs this class
          # and potentially this snippet of code in order to do the right thing.
          # TODO: test that out and delete this method if possible.
          # :nocov:
          declaration_data = declaration_data.merge(type: :detached_entity)
          # :nocov:
        end

        if self.class.model_base_class_requires_conversion?(declaration_data[:model_base_class])
          # TODO: No longer is hit in this test suite but ActiveRecordType needs this class
          # and potentially this snippet of code in order to do the right thing.
          # TODO: test that out and delete this method if possible.
          # :nocov:
          declaration_data = declaration_data.merge(model_base_class: "Foobara::DetachedEntity")
          # :nocov:
        end

        # TODO: remove private attributes, add delegated attributes
        # re: delegated attribute type... it can be required if required entire way, can be
        # allow_nil if allow_nil anywhere along the way.
        # remove private and delegated from the manifest hash.
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
      TypeDeclarations.foobara_manifest_context_detached?
    end
  end
end
