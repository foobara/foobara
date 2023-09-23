Foobara.require_file(
  "entity",
  "extensions/type_declarations/handlers/extend_model_type_declaration/model_class_desugarizer"
)

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ModelClassDesugarizer < ExtendModelTypeDeclaration::ModelClassDesugarizer
          def expected_type_symbol
            :entity
          end

          def default_model_base_class
            Foobara::Entity
          end

          def create_model_class_args(model_module:, type_declaration:)
            super.merge(primary_key: type_declaration[:primary_key])
          end
        end
      end
    end
  end
end