module Foobara
  class Model
    module SensitiveTypeRemovers
      class Model < TypeDeclarations::SensitiveTypeRemover
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
