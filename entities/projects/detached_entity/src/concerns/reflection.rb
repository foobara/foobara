module Foobara
  class DetachedEntity < Model
    module Concerns
      module Reflection
        include Concern

        module ClassMethods
          def foobara_depends_on
            foobara_associations.values.map(&:target_class).uniq
          end

          def foobara_deep_depends_on
            types = foobara_deep_associations.sort_by do |path, _type|
              [DataPath.new(path).path.size, path]
            end.map(&:last)

            types.map(&:target_class).uniq
          end

          def foobara_manifest
            associations = foobara_associations.map do |(path, type)|
              entity_class = type.target_class
              entity_name = entity_class.foobara_type.scoped_full_name

              [path, entity_name]
            end.sort.to_h

            deep_associations = foobara_deep_associations.map do |(path, type)|
              entity_class = type.target_class
              entity_name = entity_class.foobara_type.scoped_full_name

              [path, entity_name]
            end.sort.to_h

            base_manifest = superclass.respond_to?(:foobara_manifest) ? super : {}

            base_manifest.merge(
              Util.remove_blank(
                depends_on: foobara_depends_on.map(&:full_entity_name),
                deep_depends_on: foobara_deep_depends_on.map(&:full_entity_name),
                associations:,
                deep_associations:,
                entity_name: foobara_model_name,
                primary_key_attribute: foobara_primary_key_attribute,
                primary_key_type:
                  foobara_attributes_type.declaration_data[:element_type_declarations][foobara_primary_key_attribute]
              )
            )
          end
        end
      end
    end
  end
end
