require_relative "typed_transformer"

module Foobara
  module TypeDeclarations
    class RemoveSensitiveValuesTransformer < TypedTransformer
      class << self
        def type_declaration(type_declaration)
          if type_declaration.is_a?(Types::Type)
            type_declaration = type_declaration.declaration_data
          end

          TypeDeclarations.remove_sensitive_types(type_declaration)
        end
      end

      attr_accessor :namespace

      def initialize(...)
        super

        self.namespace = Namespace.current

        type
      end

      def transform(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def sanitize_value(type, value)
        if type.has_sensitive_types?
          remover_class = TypeDeclarations.sensitive_value_remover_class_for_type(type)
          remover = Namespace.use(namespace) { remover_class.new(type) }
          sanitized_value = remover.process_value!(value)

          [sanitized_value, sanitized_value != value]
        else
          [value, false]
        end
      end
    end
  end
end
