module Foobara
  class Entity < Model
    module Concerns
      module Associations
        include Concern

        module ClassMethods
          def associations
            @associations ||= construct_associations
          end

          def deep_associations
            @deep_associations ||= begin
              deep = {}

              associations.each_pair do |data_path, type|
                deep[data_path] = type

                entity_class = type.target_classes.first

                entity_class.deep_associations.each_pair do |sub_data_path, sub_type|
                  deep["#{data_path}.#{sub_data_path}"] = sub_type
                end
              end

              deep
            end
          end

          def one_association(name, *association_identifiers)
            target_association_key = association_for(association_identifiers)

            define_method name do
              # TODO: memomize but with some smart cache busting
              values = Foobara::DataPath.values_at(target_association_key, self)

              if values.size > 1
                raise "Multiple records found for #{name} association but only expected 0 or 1."
              end

              unless values.empty?
                values.first
              end
            end
          end

          def many_association(name, *association_identifiers)
            target_association_key = association_for(association_identifiers)

            define_method name do
              # TODO: memomize but with some smart cache busting
              Foobara::DataPath.values_at(target_association_key, self)
            end
          end

          def association_for(association_filters)
            if association_filters.size == 1
              data_path = association_filters.first.to_s

              if deep_assocations.key?(data_path)
                return deep_associations[data_path]
              end
            end

            result = association_filters.inject(deep_associations.keys) do |filtered, filter|
              filtered_associations(filter, filtered)
            end

            if result.empty?
              raise "Could not find association matching #{association_filters}"
            elsif result.size > 1
              raise "Multiple associations matched by #{association_filters}"
            else
              result.first
            end
          end

          def filtered_associations(filter, association_keys)
            if filter.is_a?(::Symbol)
              filter = filter.to_s
            end

            if filter.is_a?(::String)
              if filter =~ /[A-Z]/
                association_keys.select do |key|
                  type = deep_associations[key]
                  entity_class = type.target_classes.first
                  entity_class.full_entity_name.include?(filter)
                end
              else
                association_keys.select do |key|
                  key.include?(filter)
                end
              end
            elsif filter.is_a?(::Class) && filter < ::Entity
              association_keys.select do |key|
                type = deep_associations[key]
                entity_class = type.target_classes.first
                entity_class < filter
              end
            else
              raise "Not sure how to apply filter #{filter}"
            end
          end

          def construct_associations(type = attributes_type, path = DataPath.new, result = {})
            if type.extends_type?(namespace.type_for_symbol(:entity))
              result[path.to_s] = type
            elsif type.extends_type?(namespace.type_for_symbol(:array))
              # TODO: what to do about an associative array type?? Unclear how to make a key from that...
              # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
              construct_associations(type.element_type, path.append(:"#"), result)
            elsif type.extends_type?(namespace.type_for_symbol(:attributes))
              type.element_types.each_pair do |attribute_name, element_type|
                construct_associations(element_type, path.append(attribute_name), result)
              end
            elsif type.extends_type?(namespace.type_for_symbol(:associative_array))
              # not going to bother testing this for now
              # :nocov:
              if contains_associations?(type)
                raise "Associative array types with associations in them are not currently supported. " \
                      "Use attributes type if you can or set the key_type and/or value_type to duck type"
              end
              # :nocov:
            end

            result
          end

          def contains_associations?(type = entity_type, initial = true)
            if type.extends_type?(namespace.type_for_symbol(:entity))
              if initial
                contains_associations?(type.element_types, false)
              else
                true
              end
            elsif type.extends_type?(namespace.type_for_symbol(:array))
              # TODO: what to do about an associative array type?? Unclear how to make a key from that...
              # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
              contains_associations?(type.element_type, false)
            elsif type.extends_type?(namespace.type_for_symbol(:attributes))
              type.element_types.values.any? do |element_type|
                contains_associations?(element_type, false)
              end
            elsif type.extends_type?(namespace.type_for_symbol(:associative_array))
              # not going to bother testing this for now
              # :nocov:
              contains_associations?(type.key_type, false) || contains_associations?(type.value_type, false)
              # :nocov:
            end
          end

          def that_owns(record)
            associations
          end
        end
      end
    end
  end
end
