module Foobara
  class AttributesTransformer < TypeDeclarations::TypedTransformer
    class << self
      attr_accessor :only_attributes

      def type_declaration(from_type)
        from_declaration = from_type.declaration_data
        to_declaration = TypeDeclarations::Attributes.only(from_declaration, *only_attributes)

        if TypeDeclarations.declarations_equal?(from_declaration, to_declaration)
          from_type
        else
          from_type.foobara_domain.foobara_type_from_declaration(to_declaration)
        end
      end

      def only(*attribute_names)
        transformer_class = Class.new(self)
        transformer_class.only_attributes = attribute_names

        transformer_class
      end
    end

    def transform(inputs)
      inputs.slice(*allowed_keys)
    end

    def allowed_keys
      type.element_types.keys
    end
  end
end
