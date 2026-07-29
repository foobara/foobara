module Foobara
  class Model
    module SensitiveValueRemovers
      class Model < TypeDeclarations::RemoveSensitiveValuesTransformer
        def transform(record)
          attributes_type = from_type.element_types

          sanitized_attributes, _changed = sanitize_value(attributes_type, record.attributes_with_delegates)

          if from_type.declaration_data.key?(:private)
            sanitized_attributes = sanitized_attributes.except(*from_type.declaration_data[:private])
          end

          Namespace.use(to_type.created_in_namespace) do
            to_type.target_class.send(build_method, sanitized_attributes)
          end
        end

        def build_method
          :new
        end
      end
    end
  end
end
