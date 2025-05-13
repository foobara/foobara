module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      def only(*attribute_names)
        symbol = symbol_for_attribute_names(attribute_names)
        existing = Only.foobara_lookup(symbol, mode: Namespace::LookupMode::DIRECT)

        return existing if existing

        transformer_class = Class.new(Only)
        transformer_class.only_attributes = attribute_names

        Namespace::NamespaceHelpers.foobara_autoset_scoped_path(transformer_class, set_namespace: true)
        transformer_class.foobara_parent_namespace = transformer_class.scoped_namespace
        transformer_class.scoped_namespace.foobara_register(transformer_class)

        transformer_class
      end
    end

    class Only < AttributesTransformers
      class << self
        attr_accessor :only_attributes

        def symbol
          if only_attributes
            symbol_for_attribute_names(only_attributes)
          end
        end

        def will_set_scoped_path?
          true
        end
      end

      def to_type_declaration
        if from_type
          from_declaration = from_type.declaration_data
          TypeDeclarations::Attributes.only(from_declaration, *self.class.only_attributes)
        end
      end

      def from_type_declaration
        if to_type
          to_declaration = to_type.declaration_data
          TypeDeclarations::Attributes.only(to_declaration, *self.class.only_attributes)
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
