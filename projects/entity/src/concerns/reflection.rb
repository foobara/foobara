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

          def foobara_manifest(to_include:)
            associations = self.associations.map do |(path, type)|
              entity_class = type.target_class
              entity_name = entity_class.full_entity_name

              [path, entity_name]
            end.sort.to_h

            deep_associations = self.deep_associations.map do |(path, type)|
              entity_class = type.target_class
              entity_name = entity_class.full_entity_name

              [path, entity_name]
            end.sort.to_h

            {
              attributes_type: attributes_type.declaration_data,
              depends_on: depends_on.map(&:full_entity_name),
              deep_depends_on: deep_depends_on.map(&:full_entity_name),
              associations:,
              deep_associations:,
              organization_name:,
              domain_name:,
              entity_name:,
              model_base_class: entity_type.declaration_data[:model_base_class],
              model_class: entity_type.declaration_data[:model_class],
              primary_key_attribute:,
              primary_key_type: attributes_type.declaration_data[:element_type_declarations][primary_key_attribute]
            }
          end
        end
      end
    end
  end
end
