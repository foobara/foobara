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

                entity_class = type.target_class

                entity_class.deep_associations.each_pair do |sub_data_path, sub_type|
                  deep["#{data_path}.#{sub_data_path}"] = sub_type
                end
              end

              deep
            end
          end

          # TODO: stamp this metadata out somewhere, preferably on deep_associations hash somehow
          def association(name, *association_identifiers)
            target_association_key = association_for(association_identifiers)

            is_many = target_association_key.include?("#")

            define_method name do
              # TODO: memoize but with some smart cache busting
              values = Foobara::DataPath.values_at(target_association_key, self)

              if is_many
                values
              else
                if values.size > 1
                  # :nocov:
                  raise "Multiple records found for #{name} association but only expected 0 or 1."
                  # :nocov:
                end

                unless values.empty?
                  values.first
                end
              end
            end
          end

          def association_for(association_filters)
            if association_filters.size == 1
              data_path = association_filters.first.to_s

              if deep_associations.key?(data_path)
                return data_path
              end
            end

            result = association_filters.inject(deep_associations.keys) do |filtered, filter|
              filtered_associations(filter, filtered)
            end

            if result.empty?
              # :nocov:
              raise "Could not find association matching #{association_filters}"
              # :nocov:
            elsif result.size > 1
              # :nocov:
              raise "Multiple associations matched by #{association_filters}"
              # :nocov:
            else
              result.first
            end
          end

          def filtered_associations(filter, association_keys = deep_associations.keys)
            if filter.is_a?(::Symbol)
              filter = filter.to_s
            end

            if filter.is_a?(::String)
              if filter =~ /[A-Z]/
                association_keys.select do |key|
                  type = deep_associations[key]
                  entity_class = type.target_class
                  entity_class.full_entity_name.include?(filter)
                end
              else
                association_keys.select do |key|
                  key.include?(filter)
                end
              end
            elsif filter.is_a?(::Class) && filter < Entity
              association_keys.select do |key|
                type = deep_associations[key]
                entity_class = type.target_class
                entity_class == filter || entity_class < filter
              end
            else
              # :nocov:
              raise "Not sure how to apply filter #{filter}"
              # :nocov:
            end
          end

          def construct_associations(
            type = attributes_type,
            path = DataPath.new,
            result = {}
          )
            if type.extends?(:entity)
              result[path.to_s] = type
            elsif type.extends?(:tuple)
              element_types = type.element_types

              element_types&.each&.with_index do |element_type, index|
                construct_associations(element_type, path.append(index), result)
              end
            elsif type.extends?(:array)
              # TODO: what to do about an associative array type?? Unclear how to make a key from that...
              # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
              element_type = type.element_type

              if element_type
                construct_associations(element_type, path.append(:"#"), result)
              end
            elsif type.extends?(:attributes)
              type.element_types.each_pair do |attribute_name, element_type|
                construct_associations(element_type, path.append(attribute_name), result)
              end
            elsif type.extends?(:model)
              construct_associations(type.target_class.attributes_type, path, result)
            elsif type.extends?(:associative_array)
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
            if type.extends?(:entity)
              if initial
                contains_associations?(type.element_types, false)
              else
                true
              end
            elsif type.extends?(:array)
              # TODO: what to do about an associative array type?? Unclear how to make a key from that...
              # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
              element_type = type.element_type

              if element_type
                contains_associations?(element_type, false)
              end
            elsif type.extends?(:attributes)
              type.element_types.values.any? do |element_type|
                contains_associations?(element_type, false)
              end
            elsif type.extends?(:associative_array)
              element_types = type.element_types

              if element_types
                key_type, value_type = element_types

                contains_associations?(key_type, false) ||
                  contains_associations?(value_type, false)
              end
            end
          end

          def that_owns(record, filters = [])
            containing_records = that_own(record, filters)

            unless containing_records.empty?
              if containing_records.size == 1
                containing_records.first
              else
                # :nocov:
                raise "Expected only one record to own #{record} but found #{containing_records.size}"
                # :nocov:
              end
            end
          end

          def that_own(record, filters = [])
            association_key = association_for([record.class, *filters])

            data_path = DataPath.new(association_key)

            done = false

            containing_records = Util.array(record)

            until done
              last = data_path.path.last

              if last == :"#"
                method = :find_all_by_attribute_containing_any_of
                attribute_name = data_path.path[-2]
                data_path = DataPath.new(data_path.path[0..-3])
              else
                method = :find_all_by_attribute_any_of
                attribute_name = last
                data_path = DataPath.new(data_path.path[0..-2])
              end

              containing_entity_class_path = data_path.to_s

              entity_class = if containing_entity_class_path.empty?
                               done = true
                               self
                             else
                               deep_associations[
                                 containing_entity_class_path
                               ].target_class
                             end

              containing_records = entity_class.send(method, attribute_name, containing_records).to_a

              done = true unless containing_records
            end

            containing_records
          end
        end
      end
    end
  end
end
