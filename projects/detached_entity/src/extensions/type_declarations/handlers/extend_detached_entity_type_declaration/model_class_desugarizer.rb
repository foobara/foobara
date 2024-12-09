module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ModelClassDesugarizer < ExtendModelTypeDeclaration::ModelClassDesugarizer
          def expected_type_symbol
            :detached_entity
          end

          def default_model_base_class
            Foobara::DetachedEntity
          end

          def create_model_class_args(model_module:, type_declaration:)
            super.merge(primary_key: type_declaration[:primary_key])
          end
        end
      end
    end
  end
end
