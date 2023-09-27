module Foobara
  class Entity < Model
    module Concerns
      module Reflection
        include Concern

        module ClassMethods
          def foobara_manifest
            depends_on = []
            deep_depends_on = []
            associations = {}
            deep_associations = {}

            self.associations.each_pair do |path, type|
              entity_class = type.target_classes.first
              entity_name = entity_class.full_entity_name

              depends_on << entity_name

              associations[path] = entity_name
            end

            self.deep_associations.each_pair do |path, type|
              entity_class = type.target_classes.first
              entity_name = entity_class.full_entity_name

              deep_depends_on << entity_name

              deep_associations[path] = entity_name
            end

            {
              depends_on:,
              deep_depends_on:,
              associations:,
              deep_associations:
            }
          end
        end
      end
    end
  end
end
