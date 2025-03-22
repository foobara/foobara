module Foobara
  class Model
    module SensitiveValueRemovers
      class Model < TypeDeclarations::RemoveSensitiveValuesTransformer
        def transform(record)
          attributes_type = from_type.element_types

          sanitized_attributes, changed = sanitize_value(attributes_type, record.attributes)

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
