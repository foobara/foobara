module Foobara
  module TypeDeclarations
    module SensitiveValueRemovers
      class Array < RemoveSensitiveValuesTransformer
        def transform(array)
          element_type = type.element_type

          array.map do |element|
            sanitized_value, changed = sanitize_value(element_type, element)

            if changed
              sanitized_value
            else
              element
            end
          end
        end
      end
    end
  end
end
