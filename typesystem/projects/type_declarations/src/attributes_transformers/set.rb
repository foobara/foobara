module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      def next_index
        @index ||= 0
        @index += 1
      end

      def set(attribute_names_to_values)
        if attribute_names_to_values.empty?
          # :nocov:
          raise ArgumentError, "You must specify at least one attribute name/value pair"
          # :nocov:
        end

        symbol = symbol_for_attribute_names([*attribute_names_to_values.keys, next_index.to_s.to_sym])
        existing = Set.foobara_lookup(symbol, mode: Namespace::LookupMode::DIRECT)

        return existing if existing

        transformer_class = Class.new(Set)
        transformer_class.attribute_names_to_values = attribute_names_to_values

        Namespace::NamespaceHelpers.foobara_autoset_scoped_path(transformer_class, set_namespace: true)
        transformer_class.scoped_namespace.foobara_register(transformer_class)

        transformer_class
      end
    end

    class Set < AttributesTransformers
      class << self
        attr_accessor :attribute_names_to_values

        def symbol
          if attribute_names_to_values
            symbol_for_attribute_names(attribute_names_to_values.keys)
          end
        end

        def will_set_scoped_path?
          true
        end
      end

      def to_type_declaration
        # TODO: test this
        # :nocov:
        if from_type
          from_declaration = from_type.declaration_data
          TypeDeclarations::Attributes.reject(from_declaration, *self.class.attribute_names_to_values.keys)
        end
        # :nocov:
      end

      def from_type_declaration
        if to_type
          to_declaration = to_type.declaration_data
          TypeDeclarations::Attributes.reject(to_declaration, *self.class.attribute_names_to_values.keys)
        end
      end

      def transform(inputs)
        to_merge = {}

        self.class.attribute_names_to_values.each_pair do |input_name, value|
          if value.is_a?(::Proc)
            value = value.call
          end
          to_merge[input_name] = value
        end

        inputs.merge(to_merge)
      end
    end
  end
end
