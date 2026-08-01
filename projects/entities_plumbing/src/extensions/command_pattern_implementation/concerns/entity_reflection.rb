module Foobara
  module CommandPatternImplementation
    module Concerns
      module EntityReflection
        include Concern

        module ClassMethods
          def types_depended_on
            # These lookups are duplicative of the overriden method as well as other methods.
            # Likely there's some way to DRY this up
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@types_depended_on) && @types_depended_on.key?(remove_sensitive)
              return @types_depended_on[remove_sensitive]
            end

            @types_depended_on ||= {}
            @types_depended_on[remove_sensitive] = begin
              types = super

              unless depends_on_entities.empty?
                entity_types = depends_on_entities.map(&:entity_type)

                if remove_sensitive
                  entity_types = entity_types.reject(&:sensitive?)
                end

                types |= entity_types
                types |= entity_types.map(&:types_depended_on).inject(:|)
              end

              types
            end
          end
        end
      end
    end
  end
end
