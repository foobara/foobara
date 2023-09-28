module Foobara
  class Entity < Model
    module Concerns
      module Reflection
        include Concern

        module ClassMethods
          def depends_on
            associations.values.map(&:target_class).uniq
          end

          def deep_depends_on
            types = deep_associations.sort_by do |path, _type|
              [DataPath.new(path).path.size, path]
            end.map(&:last)

            types.map(&:target_class).uniq
          end

          def foobara_manifest
            associations = {}
            deep_associations = {}

            self.associations.each_pair do |path, type|
              entity_class = type.target_class
              entity_name = entity_class.full_entity_name

              associations[path] = entity_name
            end

            h = self.deep_associations.sort_by do |path, _type|
              [DataPath.new(path).path.size, path]
            end.to_h

            h.each_pair do |path, type|
              entity_class = type.target_class
              entity_name = entity_class.full_entity_name

              deep_associations[path] = entity_name
            end

            {
              depends_on: depends_on.map(&:full_entity_name),
              deep_depends_on: deep_depends_on.map(&:full_entity_name),
              associations:,
              deep_associations:
            }
          end
        end
      end
    end
  end
end
