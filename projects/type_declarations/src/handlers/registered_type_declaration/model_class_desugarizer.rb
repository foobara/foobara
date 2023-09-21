Foobara.require_file(
  "type_declarations",
  "handlers/extend_model_type_declaration/attributes_handler_desugarizer"
)

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
              type: model_class.model_symbol
            }
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
