module Foobara
  class Model
    module SensitiveTypeRemovers
      class Model < TypeDeclarations::SensitiveTypeRemover
        def applicable?(strict_type_declaration)
          strict_type_declaration.is_a?(::Hash) && strict_type_declaration.key?(:attributes_declaration)
        end

        def transform(strict_type_declaration)
          old_attributes_declaration = strict_type_declaration[:attributes_declaration]

          new_attributes_declaration = remove_sensitive_types(old_attributes_declaration)

          if new_attributes_declaration == old_attributes_declaration
            strict_type_declaration
          else
            strict_type_declaration.merge(attributes_declaration: new_attributes_declaration)
          end
        end
      end
    end
  end
end
