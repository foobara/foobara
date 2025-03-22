module Foobara
  class DetachedEntity < Model
    module SensitiveValueRemovers
      class DetachedEntity < TypeDeclarations::RemoveSensitiveValuesTransformer
        class << self
          def handles_type?(type)
            type.extends?(:detached_entity)
          end
        end

        def transform(record)
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
            type.target_class.send(build_method, sanitized_attributes)
          else
            record
          end
        end

        def build_method
          :new
        end
      end
    end
  end
end
