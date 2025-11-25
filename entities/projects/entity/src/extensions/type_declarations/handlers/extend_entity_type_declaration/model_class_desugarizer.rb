module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class ModelClassDesugarizer < ExtendDetachedEntityTypeDeclaration::ModelClassDesugarizer
          def expected_type_symbol
            :entity
          end

          def default_model_base_class
            Foobara::Entity
          end
        end
      end
    end
  end
end
