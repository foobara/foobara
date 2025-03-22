module Foobara
  class Entity < DetachedEntity
    module SensitiveValueRemovers
      class Entity < TypeDeclarations::RemoveSensitiveValuesTransformer
        class << self
          def handles_type?(type)
            type.extends?(:entity)
          end
        end

        def transform(record)
          return type.thunk(record) unless record.loaded?

          sanitized_attributes = {}

          element_types = from_type.element_types.element_types
          changed = false

          record.attributes.each_pair do |attribute_name, value|
            element_type = element_types[attribute_name]

            if element_type.sensitive?
              changed = true
              next
            else
              value, changed = sanitize_value(element_type, value)
              sanitized_attributes[attribute_name] = value
            end
          end

          if changed
            type.build(sanitized_attributes)
          else
            record
          end
        end
      end
    end
  end
end
