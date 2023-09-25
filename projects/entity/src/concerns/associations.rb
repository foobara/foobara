module Foobara
  class Entity < Model
    module Concerns
      module Associations
        include Concern

        module ClassMethods
          def associations
            @associations ||= construct_associations
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
        end
      end
    end
  end
end
