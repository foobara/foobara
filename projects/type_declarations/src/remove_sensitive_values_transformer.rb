require_relative "typed_transformer"

module Foobara
  module TypeDeclarations
    class RemoveSensitiveValuesTransformer < TypedTransformer
      def to_type_declaration
        TypeDeclarations.remove_sensitive_types(from_type.declaration_data)
      end

      def from_type_declaration
        TypeDeclarations.remove_sensitive_types(to_type.declaration_data)
      end

      def transform(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def sanitize_value(type, value)
        if type.has_sensitive_types?
          sanitized_value = Namespace.use to_type.created_in_namespace do
            remover_class = TypeDeclarations.sensitive_value_remover_class_for_type(type)
            remover = remover_class.new(from: type)
            remover.process_value!(value)
          end

          [sanitized_value, sanitized_value != value]
        else
          [value, false]
        end
      end
    end
  end
end
