module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      def reject(*attribute_names)
        transformer_class = Class.new(Reject)
        transformer_class.reject_attributes = attribute_names

        transformer_class
      end
    end

    class Reject < AttributesTransformers
      class << self
        attr_accessor :reject_attributes
      end

      def to_type_declaration
        from_declaration = from_type.declaration_data
        TypeDeclarations::Attributes.reject(from_declaration, *self.class.reject_attributes)
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
