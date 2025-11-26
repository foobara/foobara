require_relative "../sensitive_type_remover"

module Foobara
  module TypeDeclarations
    module SensitiveTypeRemovers
      class Array < SensitiveTypeRemover
        def transform(strict_type_declaration)
          old_element_declaration = strict_type_declaration[:element_type_declaration]

          new_element_declaration = remove_sensitive_types(old_element_declaration)

          if new_element_declaration == old_element_declaration
            strict_type_declaration
          else
            strict_type_declaration.merge(element_type_declaration: new_element_declaration)
          end
        end
      end
    end
  end
end
