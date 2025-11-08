require_relative "../../type_declarations/src/typed_transformer"

module Foobara
  module DetachedEntityTypesTransformers
    class DetachedEntityRemoveSensitiveValuesTransformer < TypeDeclarations::TypedTransformer
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
        already_sanitized = Set.new

        associations = Foobara::DetachedEntity.construct_deep_associations(type)

        associations&.values&.reverse&.each do |entity_type|
          next if already_sanitized.include?(entity_type)

          next if entity_type.sensitive?

          unless entity_type.has_sensitive_types?
            already_sanitized << entity_type
            next
          end

          ns = Namespace.current

          declaration = entity_type.declaration_data
          sanitized_type_declaration = TypeDeclarations.remove_sensitive_types(declaration)

          existing_type = ns.foobara_lookup(
            entity_type.full_type_symbol,
            mode: Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE
          )

          if existing_type
            if existing_type.declaration_data == sanitized_type_declaration
              already_sanitized << entity_type
              already_sanitized << existing_type
              next
            else
              # :nocov:
              raise "Did not expect to be re-sanitizing #{entity_type.full_type_symbol}"
              # :nocov:
            end

          end

          # We want to make sure that any types that change due to having sensitive types
          # has a corresponding registered type in the command registry domain if needed
          # TODO: this all feels so messy and brittle.
          Domain.current.foobara_type_from_declaration(sanitized_type_declaration)

          already_sanitized << entity_type
        end
      end
    end
  end
end
