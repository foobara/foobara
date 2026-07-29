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

            type = model_class.model_type

            if type
              declaration.declaration_data = type.foobara_manifest_reference.to_sym
              declaration.type = type
              declaration.reference_checked = true
              declaration.is_absolutified = true
              declaration.is_strict = true
              declaration.is_duped = true
              declaration.is_deep_duped = true
            else
              declaration.claimed_but_error!
            end

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
