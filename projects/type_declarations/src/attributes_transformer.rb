module Foobara
  class AttributesTransformer < TypeDeclarations::TypedTransformer
    class << self
      attr_accessor :only_attributes

      def only(*attribute_names)
        transformer_class = Class.new(self)
        transformer_class.only_attributes = attribute_names

        transformer_class
      end
    end

    def to_type_declaration
      from_declaration = from_type.declaration_data
      TypeDeclarations::Attributes.only(from_declaration, *self.class.only_attributes)
    end

    def transform(inputs)
      inputs.slice(*allowed_keys)
    end

    def allowed_keys
      to_type.element_types.keys
    end
  end
end
