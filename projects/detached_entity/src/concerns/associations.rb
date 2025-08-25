module Foobara
  class DetachedEntity < Model
    module Concerns
      module Associations
        include Concern

        module ClassMethods
          def foobara_associations
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@foobara_associations) && @foobara_associations.key?(remove_sensitive)
              return @foobara_associations[remove_sensitive]
            end

            @foobara_associations ||= {}
            @foobara_associations[remove_sensitive] = construct_associations
          end

          alias associations foobara_associations

          def foobara_deep_associations
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@foobara_deep_associations) && @foobara_deep_associations.key?(remove_sensitive)
              return @foobara_deep_associations[remove_sensitive]
            end

            @foobara_deep_associations ||= {}
            @foobara_deep_associations[remove_sensitive] = begin
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

          alias deep_associations foobara_deep_associations

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
            elsif filter.is_a?(::Class) && filter < DetachedEntity
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

          def construct_deep_associations(
            type = attributes_type,
            path = DataPath.new,
            result = {}
          )
            associations = construct_associations(type, path, result)

            deep = {}

            associations.each_pair do |data_path, association_type|
              deep[data_path] = association_type

              entity_class = association_type.target_class

              entity_class.deep_associations.each_pair do |sub_data_path, sub_type|
                deep["#{data_path}.#{sub_data_path}"] = sub_type
              end
            end

            deep
          end

          # TODO: this big switch is a problem. Hard to create new types in other projects without being able
          # to modify this switch.  Figure out what to do.
          def construct_associations(
            type = attributes_type,
            path = DataPath.new,
            result = {},
            initial: true
          )
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if initial && type.extends?(BuiltinTypes[:detached_entity])
              construct_associations(type.target_class.foobara_attributes_type, path, result, initial: false)
            elsif type.extends?(BuiltinTypes[:entity]) ||
                  (type.extends?(BuiltinTypes[:detached_entity]) && type.declaration_data[:detached_locally])
              result[path.to_s] = type
            elsif type.extends?(BuiltinTypes[:tuple])
              element_types = type.element_types

              if remove_sensitive
                # TODO: test this code path
                # :nocov:
                element_types = element_types&.reject(&:sensitive?)
                # :nocov:
              end

              element_types&.each&.with_index do |element_type, index|
                construct_associations(element_type, path.append(index), result, initial: false)
              end
            elsif type.extends?(BuiltinTypes[:array])
              # TODO: what to do about an associative array type?? Unclear how to make a key from that...
              # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
              element_type = type.element_type

              if element_type && (!remove_sensitive || !element_type.sensitive?)
                construct_associations(element_type, path.append(:"#"), result, initial: false)
              end
            elsif type.extends?(BuiltinTypes[:attributes]) # TODO: matches attributes itself instead of only subtypes
              type.element_types&.each_pair do |attribute_name, element_type|
                if remove_sensitive && element_type.sensitive?
                  next
                end

                construct_associations(element_type, path.append(attribute_name), result, initial: false)
              end
            elsif type.extends?(BuiltinTypes[:model])
              target_class = type.target_class

              method = target_class.respond_to?(:foobara_attributes_type) ? :foobara_attributes_type : :attributes_type
              attributes_type = target_class.send(method)

              if !remove_sensitive || !attributes_type.sensitive?
                construct_associations(attributes_type, path, result, initial: false)
              end
            elsif type.extends?(BuiltinTypes[:associative_array])
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
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if type.extends?(BuiltinTypes[:detached_entity])
              if initial
                contains_associations?(type.element_types, false)
              else
                true
              end
            elsif type.extends?(BuiltinTypes[:model])
              element_types = type.element_types

              if remove_sensitive
                # TODO: test this code path
                # :nocov:
                element_types = element_types&.reject(&:sensitive?)
                # :nocov:
              end

              contains_associations?(element_types, false)
            elsif type.extends?(BuiltinTypes[:tuple])
              element_types = type.element_types

              element_types&.any? do |element_type|
                if !remove_sensitive || !element_type.sensitive?
                  contains_associations?(element_type, false)
                end
              end
            elsif type.extends?(BuiltinTypes[:array])
              # TODO: what to do about an associative array type?? Unclear how to make a key from that...
              # TODO: raise if associative array contains a non-persisted record to handle this edge case for now.
              element_type = type.element_type

              if element_type && (!remove_sensitive || !element_type.sensitive?)
                contains_associations?(element_type, false)
              end
            elsif type.extends?(BuiltinTypes[:attributes])

              type.element_types&.values&.any? do |element_type|
                if !remove_sensitive || !element_type.sensitive?
                  contains_associations?(element_type, false)
                end
              end

            elsif type.extends?(BuiltinTypes[:associative_array])
              element_types = type.element_types

              if element_types
                types = element_types

                if remove_sensitive
                  types = types&.reject(&:sensitive?)
                end

                types.any? do |key_or_value_type|
                  contains_associations?(key_or_value_type, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
