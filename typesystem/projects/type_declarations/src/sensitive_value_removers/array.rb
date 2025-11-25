module Foobara
  module TypeDeclarations
    module SensitiveValueRemovers
      class Array < RemoveSensitiveValuesTransformer
        def transform(array)
          element_type = from_type.element_type

          changed = false

          sanitized_array = array.map do |element|
            sanitized_value, changed2 = sanitize_value(element_type, element)

            if changed2
              changed = true
              sanitized_value
            else
              element
            end
          end

          if changed
            sanitized_array
          else
            array
          end
        end
      end
    end
  end
end
