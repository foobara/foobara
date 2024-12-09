module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class AttributesHandlerDesugarizer < ExtendModelTypeDeclaration::AttributesHandlerDesugarizer
          def expected_type_symbol
            :detached_entity
          end
        end
      end
    end
  end
end
