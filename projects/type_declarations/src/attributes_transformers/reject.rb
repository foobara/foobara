module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      def reject(*attribute_names)
        transformer_class = Class.new(Reject)
        transformer_class.reject_attributes = attribute_names

        Namespace::NamespaceHelpers.foobara_autoset_scoped_path(transformer_class, set_namespace: true)
        transformer_class.foobara_parent_namespace = transformer_class.scoped_namespace
        transformer_class.scoped_namespace.foobara_register(transformer_class)

        transformer_class
      end
    end

    class Reject < AttributesTransformers
      class << self
        attr_accessor :reject_attributes

        def symbol
          if reject_attributes
            symbol_for_attribute_names(reject_attributes)
          end
        end

        def will_set_scoped_path?
          true
        end
      end

      def to_type_declaration
        if from_type
          from_declaration = from_type.declaration_data
          TypeDeclarations::Attributes.reject(from_declaration, *self.class.reject_attributes)
        end
      end

      def from_type_declaration
        if to_type
          to_declaration = to_type.declaration_data
          TypeDeclarations::Attributes.reject(to_declaration, *self.class.reject_attributes)
        end
      end

      def transform(inputs)
        inputs = Util.symbolize_keys(inputs)
        inputs.slice(*allowed_keys)
      end

      def allowed_keys
        to_type.element_types.keys
      end
    end
  end
end
