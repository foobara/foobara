require_relative "../remove_sensitive_values_transformer"

module Foobara
  module TypeDeclarations
    module SensitiveValueRemovers
      class Attributes < RemoveSensitiveValuesTransformer
        def transform(attributes)
          element_types = from_type.element_types

          sanitized_attributes = {}
          changed = false

          attributes.each_pair do |attribute_name, value|
            element_type = element_types[attribute_name]

            if element_type.sensitive?
              changed = true
              next
            else
              value, changed2 = sanitize_value(element_type, value)
              changed ||= changed2
              sanitized_attributes[attribute_name] = value
            end
          end

          if changed
            sanitized_attributes
          else
            attributes
          end
        end
      end
    end
  end
end
