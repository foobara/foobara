module Foobara
  class Entity < DetachedEntity
    module Concerns
      module Mutations
        include Concern

        def update_aggregate(value, type = self.class.model_type)
          # is this a smell?
          self.class.update_aggregate(self, value, type)
        end

        module ClassMethods
          def update_aggregate(object, value, type = object.class.model_type)
            return value if object.nil?

            if type.extends?(BuiltinTypes[:model])
              element_types = type.element_types.element_types

              value.each_pair do |attribute_name, new_value|
                current_value = object.read_attribute(attribute_name)

                attribute_type = element_types[attribute_name]

                updated_value = update_aggregate(current_value, new_value, attribute_type)

                object.write_attribute(attribute_name, updated_value)
              end

              object
            elsif type.extends?(BuiltinTypes[:attributes])
              element_types = type.element_types

              object = object.dup
              object ||= {}

              value.each_pair do |attribute_name, new_value|
                current_value = object[attribute_name]
                attribute_type = element_types[attribute_name]

                updated_value = update_aggregate(current_value, new_value, attribute_type)

                object[attribute_name] = updated_value
              end

              object
            elsif type.extends?(BuiltinTypes[:tuple])
              # :nocov:
              raise "Tuple not yet supported"
              # :nocov:
            elsif type.extends?(BuiltinTypes[:associative_array])
              # :nocov:
              raise "Associated array not yet supported"
              # :nocov:
            elsif type.extends?(BuiltinTypes[:array])
              element_type = type.element_type

              value.map.with_index do |element, index|
                update_aggregate(object[index], element, element_type)
              end
            else
              value
            end
          end
        end
      end
    end
  end
end
