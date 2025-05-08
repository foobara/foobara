module Foobara
  class Model
    module SensitiveTypeRemovers
      class Model < TypeDeclarations::SensitiveTypeRemover
        def applicable?(strict_type_declaration)
          strict_type_declaration.is_a?(::Hash) && strict_type_declaration.key?(:attributes_declaration)
        end

        def transform(strict_type_declaration)
          old_attributes_declaration = strict_type_declaration[:attributes_declaration]

          new_attributes_declaration = old_attributes_declaration

          if strict_type_declaration.key?(:private)
            new_attributes_declaration = TypeDeclarations::Attributes.reject(
              old_attributes_declaration,
              strict_type_declaration[:private]
            )
          end

          new_attributes_declaration = remove_sensitive_types(new_attributes_declaration)

          if new_attributes_declaration != old_attributes_declaration
            strict_type_declaration = strict_type_declaration.merge(attributes_declaration: new_attributes_declaration)
          end

          if strict_type_declaration.key?(:delegates)
            strict_type_declaration = strict_type_declaration.except(:delegates)
          end

          if strict_type_declaration.key?(:private)
            strict_type_declaration = strict_type_declaration.except(:private)
          end

          strict_type_declaration
        end
      end
    end
  end
end
