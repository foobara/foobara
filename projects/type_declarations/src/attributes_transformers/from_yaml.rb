module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      # TODO: dry this up with a .subclass method in AttributesTransformers?
      def from_yaml(*attribute_names)
        if attribute_names.empty?
          # :nocov:
          raise ArgumentError, "You must specify at least one attribute name"
          # :nocov:
        end

        symbol = symbol_for_attribute_names(attribute_names)
        existing = FromYaml.foobara_lookup(symbol, mode: Namespace::LookupMode::DIRECT)

        return existing if existing

        transformer_class = Class.new(FromYaml)
        transformer_class.from_yaml_attributes = attribute_names

        Namespace::NamespaceHelpers.foobara_autoset_scoped_path(transformer_class, set_namespace: true)
        transformer_class.foobara_parent_namespace = transformer_class.scoped_namespace
        transformer_class.scoped_namespace.foobara_register(transformer_class)

        transformer_class
      end
    end

    class FromYaml < AttributesTransformers
      class << self
        attr_accessor :from_yaml_attributes

        def symbol
          if from_yaml_attributes
            symbol_for_attribute_names(from_yaml_attributes)
          end
        end

        def will_set_scoped_path?
          true
        end
      end

      def from_type_declaration
        # TODO: verify the expected from_yaml keys are present
        declaration = to_type.declaration_data
        element_type_declarations = {}
        from_yaml = self.class.from_yaml_attributes

        declaration[:element_type_declarations].each_pair do |attribute_name, declaration_data|
          element_type_declarations[attribute_name] = if from_yaml.include?(attribute_name)
                                                        { type: :string }
                                                      else
                                                        declaration_data
                                                      end
        end

        declaration.merge(element_type_declarations:)
      end

      def transform(inputs)
        inputs = Util.symbolize_keys(inputs)

        self.class.from_yaml_attributes.each do |attribute_name|
          if inputs.key?(attribute_name)
            inputs[attribute_name] = YAML.load(inputs[attribute_name])
          end
        end

        inputs
      end
    end
  end
end
