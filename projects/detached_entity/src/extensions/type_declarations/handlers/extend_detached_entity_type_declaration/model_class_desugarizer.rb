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
        end
      end
    end
  end
end
