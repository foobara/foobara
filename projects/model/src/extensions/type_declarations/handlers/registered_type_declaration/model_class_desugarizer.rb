module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ModelClassDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.class? && sugary_type_declaration.declaration_data < Model
          end

          def desugarize(declaration)
            model_class = declaration.declaration_data

            declaration.declaration_data = model_class.model_type.foobara_manifest_reference.to_sym

            type = model_class.model_type

            if type
              declaration.type = type
              declaration.reference_checked = true
            else
              # :nocov:
              declaration.reference_checked = false
              # :nocov:
            end

            declaration.is_absolutified = true
            declaration.is_strict = true
            declaration.is_duped = true
            declaration.is_deep_duped = true

            declaration
          end

          def priority
            Priority::FIRST - 1
          end
        end
      end
    end
  end
end
