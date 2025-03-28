module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      def only(*attribute_names)
        transformer_class = Class.new(Only)
        transformer_class.only_attributes = attribute_names

        transformer_class
      end
    end

    class Only < AttributesTransformers
      class << self
        attr_accessor :only_attributes
      end

      def to_type_declaration
        from_declaration = from_type.declaration_data
        TypeDeclarations::Attributes.only(from_declaration, *self.class.only_attributes)
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
