require_relative "typed_transformer"

module Foobara
  module TypeDeclarations
    class RemoveSensitiveValuesTransformer < TypedTransformer
      def from(...)
        super.tap do
          create_all_association_types_in_current_namespace(from_type)
        end
      end

      def to(...)
        super.tap do
          create_all_association_types_in_current_namespace(to_type)
        end
      end

      def create_all_association_types_in_current_namespace(type)
        associations = Foobara::DetachedEntity.construct_deep_associations(type)

        associations&.values&.reverse&.each do |entity_type|
          next if entity_type.sensitive?
          next unless entity_type.has_sensitive_types?

          declaration = entity_type.declaration_data
          sanitized_type_declaration = TypeDeclarations.remove_sensitive_types(declaration)

          # We want to make sure that any types that change due to having sensitive types
          # has a corresponding registered type in the command registry domain if needed
          # TODO: this all feels so messy and brittle.
          Domain.current.foobara_type_from_declaration(sanitized_type_declaration)
        end
      end

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
