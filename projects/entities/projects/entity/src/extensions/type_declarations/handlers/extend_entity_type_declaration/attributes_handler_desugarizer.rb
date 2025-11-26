module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class AttributesHandlerDesugarizer < ExtendDetachedEntityTypeDeclaration::AttributesHandlerDesugarizer
          def expected_type_symbol
            :entity
          end
        end
      end
    end
  end
end
