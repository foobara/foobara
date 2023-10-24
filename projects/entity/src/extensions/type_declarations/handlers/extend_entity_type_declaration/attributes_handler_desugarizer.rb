module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        # TODO: need primary key type declaration validator!
        class AttributesHandlerDesugarizer < ExtendModelTypeDeclaration::AttributesHandlerDesugarizer
          def expected_type_symbol
            :entity
          end
        end
      end
    end
  end
end
