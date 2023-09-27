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
              entity_class = type.target_class
              entity_name = entity_class.full_entity_name

              depends_on << entity_name

              associations[path] = entity_name
            end

            h = self.deep_associations.sort_by do |path, _type|
              [DataPath.new(path).path.size, path]
            end.to_h

            h.each_pair do |path, type|
              entity_class = type.target_class
              entity_name = entity_class.full_entity_name

              deep_depends_on << entity_name

              deep_associations[path] = entity_name
            end

            {
              depends_on: depends_on.uniq,
              deep_depends_on: deep_depends_on.uniq,
              associations:,
              deep_associations:
            }
          end
        end
      end
    end
  end
end
