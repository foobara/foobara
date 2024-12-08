module Foobara
  class DetachedEntity < Model
    module Concerns
      module Reflection
        class CannotConvertRecordWithoutPrimaryKeyToJsonError < StandardError; end

        include Concern

        def inspect
          "<#{entity_name}:#{primary_key}>"
        end

        def to_json(*_args)
          primary_key&.to_json || raise(
            CannotConvertRecordWithoutPrimaryKeyToJsonError,
            "Cannot call record.to_json on unless record has a primary key. " \
            "Consider instead calling record.attributes.to_json instead."
          )
        end

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

          def foobara_manifest(to_include: Set.new)
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

            super.merge(
              Util.remove_blank(
                depends_on: depends_on.map(&:full_entity_name),
                deep_depends_on: deep_depends_on.map(&:full_entity_name),
                associations:,
                deep_associations:,
                entity_name:,
                primary_key_attribute:,
                primary_key_type: attributes_type.declaration_data[:element_type_declarations][primary_key_attribute]
              )
            )
          end
        end
      end
    end
  end
end
