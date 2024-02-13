module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ModelClassDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.is_a?(Class) && sugary_type_declaration < Model
          end

          def desugarize(model_class)
            {
              type: model_class.model_type.foobara_manifest_reference.to_sym
            }
          end

          def priority
            Priority::FIRST - 1
          end
        end
      end
    end
  end
end
